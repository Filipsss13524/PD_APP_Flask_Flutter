from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import model as mod
import os

app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)


@app.route('/upload', methods=['POST'])
def upload_file():
    """
    It takes the audio file from the application, processes it with the model and sends the result back to the user
    :return: the result of the model operation
    """
    if 'file' not in request.files or 'text' not in request.form:
        return {'error': 'No file part and text'}, 400

    # dict_result = {'HC': 'Health Client', 'PD': 'Parkinson Disease'}

    file = request.files['file']
    text = request.form['text']

    new_text = text.replace('/', '_')
    new_text_wav = new_text + '.wav'

    if file.filename == '':
        return {'error': 'No selected file'}, 400

    file_path = os.path.join(UPLOAD_FOLDER, new_text_wav)
    file.save(file_path)

    spectrogram_type = "mel"
    wav_path = file_path
    image_path = file_path.replace('.wav', '.png')
    model = mod.pull_model('mel-model.pth')

    mod.create_spectogram(spectrogram_type, wav_path, image_path)
    predicted_class = mod.classify_image(model, image_path, mod.transform)
    print(f'The predicted class is: {predicted_class}')

    return jsonify({'message': 'File successfully uploaded', 'predicted_class': predicted_class}), 200


@app.route('/api_image', methods=['POST'])
def get_image():
    """
    Sends the generated spectrogram to the user
    :return: the generated spectrogram as an image
    """
    data = request.get_json()
    query = data.get('query', '')

    new_text = query.replace('/', '_')
    new_text_png = new_text + '.png'
    image_path = os.path.join(UPLOAD_FOLDER, new_text_png)

    if os.path.exists(image_path):
        return send_file(image_path, mimetype='image/jpeg')
    else:
        return jsonify({'error': 'Image not found'}), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
