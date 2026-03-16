<?php

namespace Tests\Feature;

use App\Models\Email;
use App\Models\Mission;
use App\Services\AiService;
use App\Services\EmailIngestionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Mockery;

class EmailIngestionSyndicTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_prioritizes_syndic_from_attachments_over_body()
    {
        // 1. Prepare data
        $email = Email::create([
            'message_id' => 'test-id-123',
            'from_address' => 'sender@example.com',
            'subject' => 'Repair Needed',
            'body_text' => 'Please fix the leak. Syndic: BodySyndic',
            'received_at' => now(),
        ]);

        $aiData = [
            'classification' => 'MISSION',
            'confidence' => 0.9,
            'mission' => [
                'title' => 'Leaking pipe',
                'description' => 'A bad leak in the basement.',
                'syndicFromBody' => 'BodySyndic',
                'syndicFromAttachments' => 'AttachmentSyndic',
                'address' => [
                    'raw' => 'Street 1, Brussels',
                    'street' => 'Street',
                    'number' => '1',
                    'city' => 'Brussels'
                ],
            ]
        ];

        // 2. Mock AI Service
        $aiServiceMock = Mockery::mock(AiService::class);
        $aiServiceMock->shouldReceive('extractEmailData')->andReturn($aiData);

        // 3. Run Ingestion
        $service = new EmailIngestionService($aiServiceMock);
        $result = $service->ingest($email);

        // 4. Verification
        $this->assertTrue($result['success']);
        
        $mission = Mission::first();
        $this->assertNotNull($mission);
        $this->assertEquals('AttachmentSyndic', $mission->extracted_syndic_name);
        $this->assertEquals('AttachmentSyndic', $mission->extractedSyndicName);
    }

    public function test_it_falls_back_to_syndic_from_body_if_no_attachment_syndic()
    {
        // 1. Prepare data
        $email = Email::create([
            'message_id' => 'test-id-456',
            'from_address' => 'sender@example.com',
            'subject' => 'Repair Needed',
            'body_text' => 'Please fix the leak. Syndic: BodySyndic',
            'received_at' => now(),
        ]);

        $aiData = [
            'classification' => 'MISSION',
            'confidence' => 0.9,
            'mission' => [
                'title' => 'Leaking pipe',
                'description' => 'A bad leak in the basement.',
                'syndicFromBody' => 'BodySyndic',
                'syndicFromAttachments' => null,
                'address' => [
                    'raw' => 'Street 1, Brussels',
                    'street' => 'Street',
                    'number' => '1',
                    'city' => 'Brussels'
                ],
            ]
        ];

        // 2. Mock AI Service
        $aiServiceMock = Mockery::mock(AiService::class);
        $aiServiceMock->shouldReceive('extractEmailData')->andReturn($aiData);

        // 3. Run Ingestion
        $service = new EmailIngestionService($aiServiceMock);
        $result = $service->ingest($email);

        // 4. Verification
        $this->assertTrue($result['success']);
        
        $mission = Mission::first();
        $this->assertNotNull($mission);
        $this->assertEquals('BodySyndic', $mission->extracted_syndic_name);
    }
}
