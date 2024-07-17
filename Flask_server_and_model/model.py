import matplotlib.pyplot as plt
import librosa
import librosa.display
from torchvision.transforms import Compose, Resize, ToTensor, Normalize
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import os
import timm
import numpy as np



def create_spectogram(spectogram_type, wav_path, file_path):
  if spectogram_type.lower() == "mel":
    scale, sr = librosa.load(wav_path)
    mel_spectrogram = librosa.feature.melspectrogram(y=scale, sr=sr)
    log_mel_spectrogram = librosa.power_to_db(mel_spectrogram)
    plt.figure()
    librosa.display.specshow(log_mel_spectrogram, sr=sr, cmap='GnBu')
    plt.tight_layout()
    plt.savefig(file_path)
    plt.close()
  elif spectogram_type.lower() == "classic":
    plt.rcParams["figure.figsize"] = [7.50, 3.50]
    plt.rcParams["figure.autolayout"] = True
    fig, ax = plt.subplots()

    scale, sr = librosa.load(wav_path)
    spectrogram = librosa.stft(scale)
    spectrogram_db = librosa.amplitude_to_db(abs(spectrogram))
    img = librosa.display.specshow(spectrogram_db, sr=sr, x_axis='time', y_axis='hz', cmap='GnBu')

    plt.axis('off')
    img.axes.get_xaxis().set_visible(False)
    img.axes.get_yaxis().set_visible(False)

    plt.show()
  else:
    raise Exception(f"Spectogram {spectogram_type} type is not supported")


def classify_image(model, image_path, transform):
  # Load and transform the image
  image = Image.open(image_path).convert('RGB')  # Add .convert('RGB')
  image = transform(image).unsqueeze(0)  # Add batch dimension

  # Move image to device
  device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
  image = image.to(device)

  # Forward pass
  model.eval()  # Set model to evaluation mode
  with torch.no_grad():
      outputs = model(image)

  # Get predicted class
  _, predicted = torch.max(outputs.data, 1)

  # Map the output to the class name
  classes = ['HC', 'PD']
  predicted_class = classes[predicted.item()]

  return predicted_class

  # Define the transformations


transform = Compose([
  Resize((224, 224)),  # Resize images to 224x224
  ToTensor(),  # Convert PIL image to tensor
  Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])  # Normalize images
])


def pull_model(model_path):
  model = timm.create_model('vit_base_patch16_224', pretrained=False, num_classes=2)
  device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
  map_location = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
  model = torch.load(model_path, map_location=map_location)
  model = model.to(device)
  return model

# if __name__ == '__main__':
#   spectrogram_type = "mel"
#   wav_path = "uploads/fff-yggh-25_7_2021-M.wav"
#   image_path = 'uploads/fff-yggh-25_7_2021-M.png'
#   model = pull_model('mel-model.pth')
#
#   create_spectrogram(spectrogram_type, wav_path, image_path)
#   predicted_class = classify_image(model, image_path, transform)
#   print(f'The predicted class is: {predicted_class}')