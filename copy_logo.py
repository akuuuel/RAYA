import shutil, os
src = r"C:\Users\Thinkpad\.gemini\antigravity\brain\b232348e-e909-43d9-8fc9-bbf5b6a7c2b3\.user_uploaded\media_1793502376057_ab2ee001.jpg"
dst = r"C:\RAYA\assets\images\raya_logo.png"
os.makedirs(os.path.dirname(dst), exist_ok=True)
shutil.copy2(src, dst)
print(f"Copied to {dst}")
print(f"File size: {os.path.getsize(dst)} bytes")
