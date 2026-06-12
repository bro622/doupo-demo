#!/usr/bin/env python3
"""批量转换PNG为WebP格式"""
import os
from PIL import Image

def convert_to_webp(input_path, output_path, quality=80):
    """转换单个文件"""
    img = Image.open(input_path)
    img.save(output_path, 'WEBP', quality=quality)
    return os.path.getsize(input_path), os.path.getsize(output_path)

def batch_convert(input_dir, output_dir, quality=80):
    """批量转换目录"""
    os.makedirs(output_dir, exist_ok=True)

    total_saved = 0
    count = 0

    for root, dirs, files in os.walk(input_dir):
        for file in files:
            if file.lower().endswith('.png'):
                input_path = os.path.join(root, file)
                rel_path = os.path.relpath(input_path, input_dir)
                output_path = os.path.join(output_dir, rel_path.replace('.png', '.webp'))

                os.makedirs(os.path.dirname(output_path), exist_ok=True)

                try:
                    old_size, new_size = convert_to_webp(input_path, output_path, quality)
                    saved = old_size - new_size
                    total_saved += saved
                    count += 1
                    print(f"Converted: {rel_path} ({old_size//1024}KB -> {new_size//1024}KB, saved {saved//1024}KB)")
                except Exception as e:
                    print(f"Error converting {rel_path}: {e}")

    print(f"\nTotal: {count} files converted, {total_saved//1024}KB saved")
    return total_saved

if __name__ == "__main__":
    import sys
    quality = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    batch_convert("assets", "assets-webp", quality)
