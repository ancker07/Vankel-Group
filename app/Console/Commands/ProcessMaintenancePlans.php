<?php

namespace App\Console\Commands;

use App\Models\Intervention;
use App\Models\MaintenancePlan;
use Carbon\Carbon;
use Illuminate\Console\Command;

class ProcessMaintenancePlans extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'maintenance:process';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Analyze active maintenance plans and generate pending interventions for due dates.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting maintenance plan processing...');
        
        $plans = MaintenancePlan::where('status', 'ACTIVE')->get();
        $generatedCount = 0;
        $completedCount = 0;

        foreach ($plans as $plan) {
            $lastIntervention = $plan->interventions()->latest('created_at')->first();
            $nextDueDate = null;

            if (!$lastIntervention) {
                // First run - use start date
                $nextDueDate = Carbon::parse($plan->start_date);
            } else {
                // Subsequent run - calculate from last intervention
                $lastDate = Carbon::parse($lastIntervention->created_at);
                $interval = $plan->interval ?? 1;
                
                $nextDueDate = match ($plan->frequency) {
                    'MONTHLY' => $lastDate->copy()->addMonths($interval),
                    'QUARTERLY' => $lastDate->copy()->addMonths($interval * 3),
                    'YEARLY' => $lastDate->copy()->addYears($interval),
                    default => null,
                };
            }

            if ($nextDueDate && $nextDueDate <= now()->addWeek()) {
                // Check if the plan has expired
                if ($plan->end_date && $nextDueDate > Carbon::parse($plan->end_date)) {
                    $plan->update(['status' => 'COMPLETED']);
                    $completedCount++;
                    $this->line("Maintenance Plan #{$plan->id} reached its end date and is now COMPLETED.");
                    continue;
                }

                // Check if we already have an intervention with this scheduled date to prevent duplicates
                $exists = $plan->interventions()
                    ->whereDate('scheduled_date', $nextDueDate->toDateString())
                    ->exists();

                if ($exists) {
                    continue;
                }

                // Create the intervention
                Intervention::create([
                    'building_id' => $plan->building_id,
                    'syndic_id' => $plan->syndic_id,
                    'maintenance_plan_id' => $plan->id,
                    'title' => "[Maintenance] " . $plan->title,
                    'description' => $plan->description ?? "Automatic maintenance task based on plan schedule.",
                    'status' => 'PENDING',
                    'scheduled_date' => $nextDueDate,
                    'sector' => 'GENERAL', // Default
                    'urgency' => 'LOW',    // Maintenance is usually planned, not urgent
                ]);

                $generatedCount++;
                $this->line("Generated intervention for Maintenance Plan #{$plan->id}: {$plan->title}");
            }
        }

        $this->info("Finished. Generated: $generatedCount | Plans Completed: $completedCount");
    }
}
