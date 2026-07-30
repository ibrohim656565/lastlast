<?php

namespace App\Services;

use App\Models\Incident;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Exception\MessagingException;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FirebaseNotification;
use Throwable;

class NotificationService
{
    public function __construct(private readonly Messaging $messaging) {}

    /**
     * Publishes an "incident verified" alert to the province/district topics
     * the incident belongs to, plus the nationwide `all_tj` topic. Per
     * API_CONTRACT.md this fires on the new -> verified status transition.
     */
    public function notifyIncidentVerified(Incident $incident): void
    {
        $title = 'SafeTJ: incident verified';
        $body = sprintf('A %s incident has been verified nearby.', $incident->type);

        $data = [
            'type' => 'incident_verified',
            'incident_id' => (string) $incident->id,
        ];

        $topics = ['all_tj'];

        if ($incident->province_id) {
            $topics[] = "province_{$incident->province_id}";
        }

        if ($incident->district_id) {
            $topics[] = "district_{$incident->district_id}";
        }

        foreach ($topics as $topic) {
            $this->publishToTopic($topic, $title, $body, $data);
        }
    }

    /**
     * Manual admin-broadcast alert to an arbitrary set of topics (province,
     * district, or `all_tj` for nationwide).
     *
     * @param  string[]  $topics
     * @param  array<string, string>  $data
     */
    public function broadcast(array $topics, string $title, string $body, array $data = []): void
    {
        foreach ($topics as $topic) {
            $this->publishToTopic($topic, $title, $body, $data);
        }
    }

    /**
     * @param  array<string, string>  $data
     */
    private function publishToTopic(string $topic, string $title, string $body, array $data): void
    {
        $message = CloudMessage::withTarget('topic', $topic)
            ->withNotification(FirebaseNotification::create($title, $body))
            ->withData($data);

        try {
            $this->messaging->send($message);
        } catch (MessagingException|Throwable $e) {
            // Push delivery must never break the request/response cycle for
            // the admin action (status update) that triggered it.
            Log::warning('FCM publish failed', [
                'topic' => $topic,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
