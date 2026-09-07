<?php

namespace HiEvents\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class DiagnosticsCheckAccountsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'setup:check-accounts';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check if super admin accounts exist in the database';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Checking for super admin accounts...');
        $this->line('');

        $emails = ['flynnduerrel@gmail.com', 'menganyidamarice@gmail.com'];

        foreach ($emails as $email) {
            $this->line("Checking: {$email}");
            
            $user = DB::table('users')->where('email', $email)->first();
            
            if (!$user) {
                $this->error("  ✗ User not found in 'users' table");
                continue;
            }
            
            $this->info("  ✓ User found (id: {$user->id})");
            $this->line("    - email_verified_at: " . ($user->email_verified_at ? 'YES' : 'NO'));
            
            $accountLink = DB::table('account_user')
                ->where('user_id', $user->id)
                ->first();
            
            if (!$accountLink) {
                $this->error("  ✗ User not linked to any account in 'account_user' table");
                continue;
            }
            
            $this->info("  ✓ User linked to account (account_id: {$accountLink->account_id}, role: {$accountLink->role})");
            $this->line("    - status: {$accountLink->status}");
            
            $account = DB::table('accounts')->where('id', $accountLink->account_id)->first();
            if ($account) {
                $this->info("  ✓ Account exists (id: {$account->id})");
                $this->line("    - account_verified_at: " . ($account->account_verified_at ? 'YES' : 'NO'));
            } else {
                $this->error("  ✗ Account not found");
            }
            
            $this->line('');
        }

        $this->info('Check complete!');

        return 0;
    }
}
