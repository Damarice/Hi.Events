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
        $this->info('Creating/Verifying super admin accounts...');
        $this->line('');

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
                $this->line("Processing: {$adminData['email']}");
                
                // Check if user already exists
                $existingUser = DB::table('users')->where('email', $adminData['email'])->first();

                if ($existingUser) {
                    $this->info("  ✓ User already exists (id: {$existingUser->id})");
                    
                    // Verify it's linked to an account
                    $accountLink = DB::table('account_user')
                        ->where('user_id', $existingUser->id)
                        ->first();
                    
                    if (!$accountLink) {
                        // Create account and link
                        $accountId = DB::table('accounts')->insertGetId([
                            'currency' => 'USD',
                            'timezone' => 'America/New_York',
                            'account_verified_at' => now(),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);

                        DB::table('account_user')->insert([
                            'account_id' => $accountId,
                            'user_id' => $existingUser->id,
                            'role' => 'SUPERADMIN',
                            'status' => 'ACTIVE',
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                        
                        $this->info("  ✓ Linked to new account (account_id: {$accountId})");
                    } else {
                        $this->info("  ✓ Already linked to account (account_id: {$accountLink->account_id})");
                        
                        // Ensure status is ACTIVE
                        if ($accountLink->status !== 'ACTIVE') {
                            DB::table('account_user')
                                ->where('id', $accountLink->id)
                                ->update(['status' => 'ACTIVE']);
                            $this->info("  ✓ Status updated to ACTIVE");
                        }
                    }
                } else {
                    // Create everything from scratch
                    $accountId = DB::table('accounts')->insertGetId([
                        'currency' => 'USD',
                        'timezone' => 'America/New_York',
                        'account_verified_at' => now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    $userId = DB::table('users')->insertGetId([
                        'email' => $adminData['email'],
                        'first_name' => $adminData['first_name'],
                        'last_name' => $adminData['last_name'],
                        'password' => Hash::make($adminData['password']),
                        'email_verified_at' => now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    DB::table('account_user')->insert([
                        'account_id' => $accountId,
                        'user_id' => $userId,
                        'role' => 'SUPERADMIN',
                        'status' => 'ACTIVE',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    $this->info("✓ Super admin created (user_id: {$userId}, account_id: {$accountId})");
                }

                $this->line("  Password: {$adminData['password']}");
                $this->line('');

            } catch (\Exception $e) {
                $this->error("✗ Error processing {$adminData['email']}: {$e->getMessage()}");
                $this->line('');
            }
        }

        $this->info('Super admin accounts setup complete!');
        $this->line('');
        $this->info('Login credentials:');
        $this->line('  Email: flynnduerrel@gmail.com');
        $this->line('  Password: Password123!');
        $this->line('');
        $this->line('  Email: menganyidamarice@gmail.com');
        $this->line('  Password: Password123!');
        $this->line('');
        $this->info('Login at: https://hi-events-g3dx.onrender.com/auth/login');

        return 0;
    }
}
