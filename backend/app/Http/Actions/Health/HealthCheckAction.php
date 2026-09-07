<?php

namespace HiEvents\Http\Actions\Health;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;

class HealthCheckAction
{
    public function __invoke(): JsonResponse
    {
        $checks = [
            'status' => 'ok',
            'database' => $this->checkDatabase(),
            'jwt_config' => $this->checkJwtConfig(),
            'app_config' => $this->checkAppConfig(),
            'timestamp' => now()->toIso8601String(),
        ];

        $allHealthy = $checks['database']['ok']
            && $checks['jwt_config']['ok']
            && $checks['app_config']['ok'];

        return response()->json($checks, $allHealthy ? 200 : 500);
    }

    private function checkDatabase(): array
    {
        try {
            $result = DB::select('SELECT 1');
            $tables = DB::select("
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                LIMIT 5
            ");
            
            return [
                'ok' => true,
                'message' => 'Database connected',
                'sample_tables_found' => count($tables),
                'tables' => array_map(fn($t) => $t->table_name, $tables),
            ];
        } catch (\Exception $e) {
            return [
                'ok' => false,
                'message' => 'Database connection failed',
                'error' => $e->getMessage(),
            ];
        }
    }

    private function checkJwtConfig(): array
    {
        $checks = [];
        
        $jwtSecret = env('JWT_SECRET');
        $checks['jwt_secret_set'] = !empty($jwtSecret);
        
        $jwtAlgo = env('JWT_ALGO', 'HS256');
        $checks['jwt_algo'] = $jwtAlgo;
        
        $jwtTtl = env('JWT_TTL', '604800');
        $checks['jwt_ttl'] = $jwtTtl;
        
        $appKey = env('APP_KEY');
        $checks['app_key_set'] = !empty($appKey);
        
        return [
            'ok' => $checks['jwt_secret_set'] && $checks['app_key_set'],
            'checks' => $checks,
        ];
    }

    private function checkAppConfig(): array
    {
        return [
            'ok' => true,
            'app_env' => env('APP_ENV'),
            'app_debug' => env('APP_DEBUG'),
            'saas_mode_enabled' => env('APP_SAAS_MODE_ENABLED'),
            'timezone' => config('app.timezone'),
        ];
    }
}
