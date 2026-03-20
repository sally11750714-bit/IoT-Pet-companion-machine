import os
import time
from flask import Flask, send_file, jsonify, Response
import cv2

app = Flask(__name__)

# 设置文件保存的目录
save_dir = 'D:/all/media'
if not os.path.exists(save_dir):
    os.makedirs(save_dir)

camera = cv2.VideoCapture(0)  # 摄像头设备编号
is_recording = False
video_writer = None
video_filename = None

# 生成视频流帧
def generate_frames():
    while True:
        success, frame = camera.read()
        if not success:
            break
        else:
            _, buffer = cv2.imencode('.jpg', frame)
            frame = buffer.tobytes()
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

# 拍照并保存
@app.route('/capture_photo', methods=['POST'])
def capture_photo():
    success, frame = camera.read()
    if success:
        timestamp = time.strftime('%Y%m%d_%H%M%S')
        filename = f'photo_{timestamp}.jpg'
        filepath = os.path.join(save_dir, filename)
        cv2.imwrite(filepath, frame)
        return jsonify({"status": "success", "message": "Photo captured", "filename": filename})
    return jsonify({"status": "error", "message": "Failed to capture photo"})

# 启动录制
@app.route('/start_recording', methods=['POST'])
def start_recording():
    global is_recording, video_writer, video_filename
    if not is_recording:
        timestamp = time.strftime('%Y%m%d_%H%M%S')
        video_filename = f'video_{timestamp}.avi'
        frame_width = int(camera.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(camera.get(cv2.CAP_PROP_FRAME_HEIGHT))
        video_writer = cv2.VideoWriter(os.path.join(save_dir, video_filename), cv2.VideoWriter_fourcc(*'XVID'), 20.0, (frame_width, frame_height))
        is_recording = True
        return jsonify({"status": "success", "message": "Recording started"})
    return jsonify({"status": "error", "message": "Already recording"})

# 停止录制
@app.route('/stop_recording', methods=['POST'])
def stop_recording():
    global is_recording, video_writer, video_filename
    if is_recording:
        is_recording = False
        video_writer.release()
        video_filename_with_path = os.path.join(save_dir, video_filename)
        return jsonify({"status": "success", "message": "Recording stopped", "filename": video_filename_with_path})
    return jsonify({"status": "error", "message": "Not currently recording"})

# 获取文件
@app.route('/get_file/<filename>')
def get_file(filename):
    try:
        file_path = os.path.join(save_dir, filename)
        if os.path.exists(file_path):
            return send_file(file_path)
        else:
            return jsonify({"error": "File not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 在程序退出时释放摄像头资源
import atexit
atexit.register(lambda: camera.release())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
