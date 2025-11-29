from PIL import Image
import os

def create_ico(icon_paths, output_path):
    images = []
    for path in icon_paths:
        if os.path.exists(path):
            try:
                img = Image.open(path)
                images.append(img)
                print(f"Loaded {path}")
            except Exception as e:
                print(f"Error loading {path}: {e}")
        else:
            print(f"File not found: {path}")

    if images:
        try:
            images[0].save(output_path, format='ICO', sizes=[(img.width, img.height) for img in images], append_images=images[1:])
            print(f"Successfully created {output_path}")
        except Exception as e:
            print(f"Error saving ICO: {e}")
    else:
        print("No images loaded to create ICO.")

if __name__ == "__main__":
    icon_files = [
        r"c:\Users\Administrator\Desktop\UI\16.png",
        r"c:\Users\Administrator\Desktop\UI\48.png",
        r"c:\Users\Administrator\Desktop\UI\256.png"
    ]
    output_ico = r"c:\Users\Administrator\Desktop\UI\vpn_ui_demo\windows\runner\resources\app_icon.ico"
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_ico), exist_ok=True)
    
    create_ico(icon_files, output_ico)
