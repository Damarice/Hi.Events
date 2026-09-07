<?php

namespace HiEvents\Http\Actions\Status;

use Illuminate\Http\JsonResponse;

class StatusAction
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'app' => 'Hi.Events',
            'time' => date('Y-m-d H:i:s'),
            'php_version' => PHP_VERSION,
        ]);
    }
}
