$src = "C:\Users\Thinkpad\.gemini\antigravity\brain\b232348e-e909-43d9-8fc9-bbf5b6a7c2b3\.user_uploaded\media_1793502376057_ab2ee001.jpg"
$dst = "C:\RAYA\assets\images\raya_logo.png"
New-Item -ItemType Directory -Force -Path "C:\RAYA\assets\images" | Out-Null
Copy-Item -Path $src -Destination $dst -Force
Write-Output "Logo copy done: $dst"
