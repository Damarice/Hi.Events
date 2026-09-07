<?php

namespace HiEvents\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class CreateSuperAdminsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'setup:create-super-admins';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Create super admin accounts for Hi.Events';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Creating super admin accounts...');

        $admins = [
            [
                'email' => 'flynnduerrel@gmail.com',
                'first_name' => 'Flynn',
                'last_name' => 'Duerrel',
                'password' => 'Password123!',
            ],
            [
                'email' => 'menganyidamarice@gmail.com',
                'first_name' => 'Menganyi',
                'last_name' => 'Damarice',
                'password' => 'Password123!',
            ],
        ];

        foreach ($admins as $adminData) {
            try {
                // Check if account already exists
                $existingUser = DB::table('users')->where('email', $adminData['email'])->first();

                if ($existingUser) {
                    $this->warn("Account {$adminData['email']} already exists. Skipping...");
                    continue;
                }

                // Create account
                $accountId = DB::table('accounts')->insertGetId([
                    'currency' => 'USD',
                    'timezone' => 'America/New_York',
                    'account_verified_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Create user
                $userId = DB::table('users')->insertGetId([
                    'email' => $adminData['email'],
                    'first_name' => $adminData['first_name'],
                    'last_name' => $adminData['last_name'],
                    'password' => Hash::make($adminData['password']),
                    'email_verified_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Link user to account as SUPERADMIN
                DB::table('account_user')->insert([
                    'account_id' => $accountId,
                    'user_id' => $userId,
                    'role' => 'SUPERADMIN',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $this->info("✓ Super admin created: {$adminData['email']}");
                $this->line("  Password: {$adminData['password']}");

            } catch (\Exception $e) {
                $this->error("✗ Error creating {$adminData['email']}: {$e->getMessage()}");
            }
        }

        $this->info('');
        $this->info('Super admin accounts setup complete!');
        $this->info('Login at: https://hi-events-g3dx.onrender.com/auth/login');

        return 0;
    }
}
