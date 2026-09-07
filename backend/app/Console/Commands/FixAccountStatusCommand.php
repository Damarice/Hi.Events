<?php

namespace HiEvents\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class FixAccountStatusCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'setup:fix-account-status';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Fix account status to ACTIVE for super admin accounts';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Fixing account status for super admin accounts...');
        $this->line('');

        $emails = ['flynnduerrel@gmail.com', 'menganyidamarice@gmail.com'];

        foreach ($emails as $email) {
            $user = DB::table('users')->where('email', $email)->first();
            
            if (!$user) {
                $this->warn("User {$email} not found - skipping");
                continue;
            }
            
            $updated = DB::table('account_user')
                ->where('user_id', $user->id)
                ->update(['status' => 'ACTIVE']);
            
            if ($updated > 0) {
                $this->info("✓ Updated status to ACTIVE for {$email}");
            } else {
                $this->warn("{$email} not linked to any account");
            }
        }

        $this->info('');
        $this->info('Status update complete!');

        return 0;
    }
}
