<!DOCTYPE html>
<html lang="{{ $lang }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $t['header'] }}</title>
    <style>
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #09090b;
            color: #d4d4d8;
            margin: 0;
            padding: 0;
            line-height: 1.6;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #09090b;
            border: 1px solid #27272a;
            border-radius: 16px;
            overflow: hidden;
            margin-top: 20px;
            margin-bottom: 20px;
        }
        .header {
            background-color: #000;
            padding: 32px;
            border-bottom: 1px solid #18181b;
            text-align: center;
        }
        .header h1 {
            color: #22c55e; /* Brand Green */
            font-size: 14px;
            font-weight: 900;
            text-transform: uppercase;
            letter-spacing: 0.2em;
            margin: 0;
        }
        .content {
            padding: 32px;
        }
        .title {
            color: #ffffff;
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 8px;
        }
        .subtitle {
            font-size: 14px;
            color: #71717a;
            margin-bottom: 24px;
        }
        .section {
            background-color: #18181b;
            border: 1px solid #27272a;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 24px;
        }
        .section-title {
            font-size: 10px;
            font-weight: 900;
            text-transform: uppercase;
            letter-spacing: 0.1em;
            color: #71717a;
            margin-bottom: 12px;
        }
        .info-row {
            display: flex;
            margin-bottom: 8px;
        }
        .info-label {
            font-weight: 700;
            width: 120px;
            color: #a1a1aa;
            font-size: 12px;
        }
        .info-value {
            flex: 1;
            color: #ffffff;
            font-size: 14px;
        }
        .description-box {
            background-color: #09090b;
            border: 1px solid #27272a;
            border-radius: 8px;
            padding: 16px;
            font-size: 14px;
            color: #e4e4e7;
            white-space: pre-wrap;
        }
        .attachments-list {
            margin-top: 12px;
            font-size: 12px;
            color: #22c55e;
        }
        .footer {
            padding: 24px;
            text-align: center;
            font-size: 12px;
            color: #52525b;
            border-top: 1px solid #18181b;
        }
        .accent-green {
            color: #22c55e;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{ $t['header'] }}</h1>
        </div>
        
        <div class="content">
            <h2 class="title">{{ \App\Support\MessageText::field($intervention, 'title', $lang) }}</h2>
            <p class="subtitle">{{ strtr($t['done_on'], ['{date}' => \App\Support\MessageText::date($intervention->completed_at)]) }}</p>
            
            <div class="section">
                <div class="section-title">{{ $t['building'] }}</div>
                <div class="info-row">
                    <div class="info-label">{{ $t['address'] }}</div>
                    <div class="info-value">{{ $building->address }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">{{ $t['city'] }}</div>
                    <div class="info-value">{{ $building->city }}</div>
                </div>
                @if($syndic)
                <div class="info-row">
                    <div class="info-label">{{ $t['syndic'] }}</div>
                    <div class="info-value">{{ $syndic->company_name ?? $syndic->companyName ?? '' }}</div>
                </div>
                @endif
            </div>

            <div class="section">
                <div class="section-title">{{ $t['technical'] }}</div>
                <div class="info-row">
                    <div class="info-label">{{ $t['category'] }}</div>
                    <div class="info-value accent-green">{{ $intervention->category }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">{{ $t['status'] }}</div>
                    <div class="info-value">
                        @if($intervention->status === 'COMPLETED')
                            {{ $t['completed'] }}
                        @elseif($intervention->status === 'DELAYED')
                            {{ $t['delayed'] }}
                        @else
                            {{ $intervention->status }}
                        @endif
                    </div>
                </div>
                @if($intervention->admin_feedback)
                <div style="margin-top: 15px;">
                    <div class="section-title">{{ $t['admin_note'] }}</div>
                    <div class="description-box">{{ $intervention->admin_feedback }}</div>
                </div>
                @endif

                @if($intervention->status === 'DELAYED' && ($intervention->delay_reason || $intervention->delay_details))
                <div style="margin-top: 15px; border-top: 1px solid #3f3f46; pt: 15px;">
                    <div class="section-title" style="color: #f97316;">{{ $t['delay_details'] }}</div>
                    <div class="info-row">
                        <div class="info-label">{{ $t['reason'] }}</div>
                        <div class="info-value">{{ \App\Support\MessageText::word('delay_reason', $intervention->delay_reason, $lang) }}</div>
                    </div>
                    @if($intervention->delay_details)
                    <div class="description-box" style="border-color: #f97316; margin-top: 10px;">{{ $intervention->delay_details }}</div>
                    @endif
                    @if($intervention->delayed_reschedule_date)
                    <div class="info-row" style="margin-top: 10px;">
                        <div class="info-label">{{ $t['new_date'] }}</div>
                        <div class="info-value">{{ \App\Support\MessageText::date($intervention->delayed_reschedule_date) }}</div>
                    </div>
                    @endif
                </div>
                @endif
            </div>

            <div class="section">
                <div class="section-title">{{ $t['description'] }}</div>
                <div class="description-box">{{ \App\Support\MessageText::field($intervention, 'description', $lang) }}</div>
            </div>

        </div>

        <div class="footer">
            &copy; {{ date('Y') }} Vanakel Group. {{ $t['rights'] }}<br>
            {{ $t['automatic'] }}
        </div>
    </div>
</body>
</html>
