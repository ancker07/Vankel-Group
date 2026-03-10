<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .content { margin-top: 20px; }
        .footer { margin-top: 40px; font-size: 12px; color: #888; border-top: 1px solid #eee; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="content">
            {!! nl2br(e($replyBody)) !!}
        </div>
        <div class="footer">
            <p>Cet e-mail a été envoyé depuis le système de gestion du groupe Vanakel.</p>
        </div>
    </div>
</body>
</html>
