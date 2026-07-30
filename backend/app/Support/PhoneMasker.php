<?php

namespace App\Support;

class PhoneMasker
{
    /**
     * Masks a Tajik phone number for public display on incident reports,
     * e.g. "+992931234512" -> "+992 9* *** **12".
     *
     * Tajik mobile numbers are +992 followed by 9 digits, conventionally
     * grouped 2-3-4 (e.g. 93 123 4512). We reveal only the first digit of
     * the first group and the last two digits of the last group; anything
     * else, including non-Tajik numbers, falls back to a generic
     * first-1/last-2-digits mask so the function never throws on odd input.
     */
    public static function mask(?string $phone): ?string
    {
        if (! $phone) {
            return null;
        }

        $digits = preg_replace('/\D+/', '', $phone);

        if ($digits === null || strlen($digits) < 6) {
            return $phone === '' ? '' : str_repeat('*', max(strlen($phone), 1));
        }

        if (str_starts_with($digits, '992') && strlen($digits) === 12) {
            $national = substr($digits, 3);
            $group1 = substr($national, 0, 2);
            $group2 = substr($national, 2, 3);
            $group3 = substr($national, 5, 4);

            return sprintf(
                '+992 %s%s %s %s%s',
                $group1[0],
                str_repeat('*', strlen($group1) - 1),
                str_repeat('*', strlen($group2)),
                str_repeat('*', strlen($group3) - 2),
                substr($group3, -2),
            );
        }

        $prefix = substr($digits, 0, 2);
        $suffix = substr($digits, -2);
        $middle = str_repeat('*', max(strlen($digits) - 4, 1));

        return "+{$prefix}{$middle}{$suffix}";
    }
}
