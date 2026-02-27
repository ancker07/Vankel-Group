<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'intervention - Vanakel Group</title>
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
            <h1>Vanakel Group - Rapport d'intervention</h1>
        </div>
        
        <div class="content">
            <h2 class="title">{{ $intervention->title }}</h2>
            <p class="subtitle">Intervention effectuée le {{ \Carbon\Carbon::parse($intervention->completed_at ?? now())->format('d/m/Y') }}</p>
            
            <div class="section">
                <div class="section-title">Informations de l'immeuble</div>
                <div class="info-row">
                    <div class="info-label">Adresse :</div>
                    <div class="info-value">{{ $building->address }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Ville :</div>
                    <div class="info-value">{{ $building->city }}</div>
                </div>
                @if($syndic)
                <div class="info-row">
                    <div class="info-label">Syndic :</div>
                    <div class="info-value">{{ $syndic->companyName }}</div>
                </div>
                @endif
            </div>

            <div class="section">
                <div class="section-title">Détails techniques</div>
                <div class="info-row">
                    <div class="info-label">Catégorie :</div>
                    <div class="info-value accent-green">{{ $intervention->category }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Status :</div>
                    <div class="info-value">
                        @if($intervention->status === 'COMPLETED')
                            Terminé
                        @elseif($intervention->status === 'DELAYED')
                            Retardé
                        @else
                            {{ $intervention->status }}
                        @endif
                    </div>
                </div>
                @if($intervention->admin_feedback)
                <div style="margin-top: 15px;">
                    <div class="section-title">Note technique</div>
                    <div class="description-box">{{ $intervention->admin_feedback }}</div>
                </div>
                @endif
            </div>

            <div class="section">
                <div class="section-title">Description d'origine</div>
                <div class="description-box">{{ $intervention->description }}</div>
            </div>

            @if($intervention->documents->count() > 0)
            <div style="padding: 0 8px;">
                <p style="font-size: 12px; font-weight: bold; margin-bottom: 4px;">Pièces jointes incluses :</p>
                @foreach($intervention->documents as $doc)
                    <div style="font-size: 12px; color: #71717a; margin-bottom: 2px;">• {{ $doc->file_name }}</div>
                @endforeach
            </div>
            @endif
        </div>

        <div class="footer">
            &copy; {{ date('Y') }} Vanakel Group. Tous droits réservés.<br>
            Ceci est un rapport automatique généré par Vanakel Management.
        </div>
    </div>
</body>
</html>
