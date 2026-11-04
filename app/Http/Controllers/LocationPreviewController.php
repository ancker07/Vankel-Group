<?php

namespace App\Http\Controllers;

use App\Services\AiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class LocationPreviewController extends Controller
{
    public function resolve(Request $request, AiService $aiService)
    {
        $validated = $request->validate([
            'address' => ['required', 'string', 'max:255'],
        ]);

        $address = $this->normalizeAddress($validated['address']);

        if ($address === '') {
            return response()->json(['available' => false]);
        }

        foreach (['nominatim', 'photon'] as $provider) {
            $point = $provider === 'nominatim'
                ? $this->fromNominatim($address)
                : $this->fromPhoton($address);

            if ($point !== null) {
                return response()->json(['available' => true, 'source' => $provider] + $point);
            }
        }

        $point = $aiService->resolveCoordinates($address);

        return $point === null
            ? response()->json(['available' => false])
            : response()->json(['available' => true, 'source' => 'ai'] + $point);
    }

    private function fromNominatim(string $address): ?array
    {
        try {
            $result = Http::timeout(8)
                ->withHeaders(['User-Agent' => 'VanakelGroup/1.0 location-preview'])
                ->get('https://nominatim.openstreetmap.org/search', [
                    'q' => $address,
                    'format' => 'jsonv2',
                    'limit' => 1,
                    'countrycodes' => 'be',
                ])
                ->json();

            return $this->point($result[0]['lat'] ?? null, $result[0]['lon'] ?? null);
        } catch (\Throwable $exception) {
            Log::info('Nominatim location fallback failed.', ['message' => $exception->getMessage()]);
            return null;
        }
    }

    private function fromPhoton(string $address): ?array
    {
        try {
            $result = Http::timeout(8)
                ->get('https://photon.komoot.io/api/', [
                    'q' => $address,
                    'limit' => 1,
                    'lang' => 'fr',
                ])
                ->json();
            $coordinates = $result['features'][0]['geometry']['coordinates'] ?? [];

            return $this->point($coordinates[1] ?? null, $coordinates[0] ?? null);
        } catch (\Throwable $exception) {
            Log::info('Photon location fallback failed.', ['message' => $exception->getMessage()]);
            return null;
        }
    }

    private function point(mixed $latitude, mixed $longitude): ?array
    {
        if (!is_numeric($latitude) || !is_numeric($longitude)) {
            return null;
        }

        $latitude = (float) $latitude;
        $longitude = (float) $longitude;

        return $latitude >= -90 && $latitude <= 90 && $longitude >= -180 && $longitude <= 180
            ? ['latitude' => $latitude, 'longitude' => $longitude]
            : null;
    }

    private function normalizeAddress(string $address): string
    {
        $parts = array_filter(array_map('trim', explode(',', $address)), fn ($part) => $part !== '' && strcasecmp($part, 'unknown') !== 0);
        $normalized = implode(', ', $parts);

        return preg_match('/\b(belgium|belgique|belgië|be)\b/i', $normalized)
            ? $normalized
            : "{$normalized}, Belgium";
    }
}
