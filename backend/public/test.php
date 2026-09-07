<?php

echo json_encode([
    'status' => 'ok',
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION,
    'message' => 'Raw PHP test - Laravel not loaded yet'
]);
