from flask import Flask, request, jsonify
from flask_cors import CORS
import RPi.GPIO as GPIO
import time
import threading

# ====================== 基本設置區域 ======================
app = Flask(__name__)
CORS(app)  # 啟用跨域訪問 (CORS)

# GPIO 引腳配置
LEFT_IN1, LEFT_IN2 = 17, 18  # 左側馬達控制引腳
RIGHT_IN1, RIGHT_IN2 = 22, 23  # 右側馬達控制引腳
IR_SENSOR = 24  # 紅外線傳感器引腳
LASER_PIN = 27  # 雷射控制引腳
IN1, IN2, IN3, IN4 = 4, 5, 6, 7  # 步進馬達控制引腳

# 步進馬達的步進序列
steps = [
    [1, 0, 0, 0],
    [1, 1, 0, 0],
    [0, 1, 0, 0],
    [0, 1, 1, 0],
    [0, 0, 1, 0],
    [0, 0, 1, 1],
    [0, 0, 0, 1],
    [1, 0, 0, 1]
]

# 全域變數
auto_mode = False  # 自動模式標誌

# 初始化 GPIO
GPIO.setmode(GPIO.BCM)  # 使用 BCM 編號方式
GPIO.setup(LEFT_IN1, GPIO.OUT)
GPIO.setup(LEFT_IN2, GPIO.OUT)
GPIO.setup(RIGHT_IN1, GPIO.OUT)
GPIO.setup(RIGHT_IN2, GPIO.OUT)
GPIO.setup(IR_SENSOR, GPIO.IN)
GPIO.setup(LASER_PIN, GPIO.OUT)
GPIO.setup(IN1, GPIO.OUT)
GPIO.setup(IN2, GPIO.OUT)
GPIO.setup(IN3, GPIO.OUT)
GPIO.setup(IN4, GPIO.OUT)

# ====================== 機器人移動控制區域 ======================
def move_forward(slow=False):  # 前進
    GPIO.output(LEFT_IN1, GPIO.LOW)
    GPIO.output(LEFT_IN2, GPIO.HIGH)
    GPIO.output(RIGHT_IN1, GPIO.LOW)
    GPIO.output(RIGHT_IN2, GPIO.HIGH)
    if slow:
        time.sleep(0.05)

def move_backward():  # 後退
    GPIO.output(LEFT_IN1, GPIO.HIGH)
    GPIO.output(LEFT_IN2, GPIO.LOW)
    GPIO.output(RIGHT_IN1, GPIO.HIGH)
    GPIO.output(RIGHT_IN2, GPIO.LOW)
    time.sleep(0.05)

def turn_left(slow=False):  # 左轉
    GPIO.output(LEFT_IN1, GPIO.HIGH)
    GPIO.output(LEFT_IN2, GPIO.LOW)
    GPIO.output(RIGHT_IN1, GPIO.LOW)
    GPIO.output(RIGHT_IN2, GPIO.HIGH)
    if slow:
        time.sleep(0.05)

def turn_right(slow=False):  # 右轉
    GPIO.output(LEFT_IN1, GPIO.LOW)
    GPIO.output(LEFT_IN2, GPIO.HIGH)
    GPIO.output(RIGHT_IN1, GPIO.HIGH)
    GPIO.output(RIGHT_IN2, GPIO.LOW)
    if slow:
        time.sleep(0.05)

def stop():  # 停止
    GPIO.output(LEFT_IN1, GPIO.LOW)
    GPIO.output(LEFT_IN2, GPIO.LOW)
    GPIO.output(RIGHT_IN1, GPIO.LOW)
    GPIO.output(RIGHT_IN2, GPIO.LOW)

# ====================== 自動模式控制區域 ======================
def auto_move():  
    global auto_mode
    while auto_mode:  # 當自動模式啟用時
        if GPIO.input(IR_SENSOR) == GPIO.LOW:  # 偵測障礙物
            move_backward()  # 後退
            time.sleep(0.2)
            turn_left(slow=True)  # 慢速左轉
        else:
            move_forward(slow=True)  # 慢速前進
        time.sleep(0.8)  # 每次行動後暫停 0.8 秒
    stop()  # 自動模式結束後停止

def start_auto_mode():  # 啟動自動模式
    global auto_mode
    if not auto_mode:
        auto_mode = True
        threading.Thread(target=auto_move).start()

def stop_auto_mode():  # 停止自動模式
    global auto_mode
    if auto_mode:
        auto_mode = False

# ====================== 雷射控制區域 ======================
@app.route('/laser/on', methods=['GET'])  # 打開雷射
def laser_on():
    GPIO.output(LASER_PIN, GPIO.HIGH)
    return jsonify({"status": "Laser is ON"})

@app.route('/laser/off', methods=['GET'])  # 關閉雷射
def laser_off():
    GPIO.output(LASER_PIN, GPIO.LOW)
    return jsonify({"status": "Laser is OFF"})

# ====================== 步進馬達控制區域 ======================
def move_step_motor(steps, delay, rotations=1):
    total_steps = len(steps) * rotations
    for i in range(total_steps):
        for step in steps:
            GPIO.output(IN1, step[0])
            GPIO.output(IN2, step[1])
            GPIO.output(IN3, step[2])
            GPIO.output(IN4, step[3])
            time.sleep(delay)

@app.route('/move', methods=['POST'])  # 控制步進電機
def move():
    data = request.json
    direction = data.get('direction', 'forward')
    delay = 0.002  # 每步的延遲時間
    rotations = data.get('rotations', 5)  # 預設旋轉圈數

    if direction == 'backward':  # 反向旋轉
        move_step_motor(steps[::-1], delay, rotations)
    else:  # 正向旋轉
        move_step_motor(steps, delay, rotations)

    return jsonify({"status": "success"})

# ====================== 控制 API 區域 ======================
@app.route('/control', methods=['POST'])  # 控制機器人移動
def control():
    global auto_mode
    direction = request.json.get('direction')  # 獲取指令

    if direction == 'forward':  # 前進
        stop_auto_mode()
        move_forward()
    elif direction == 'backward':  # 後退
        stop_auto_mode()
        move_backward()
    elif direction == 'left':  # 左轉
        stop_auto_mode()
        turn_left()
    elif direction == 'right':  # 右轉
        stop_auto_mode()
        turn_right()
    elif direction == 'stop':  # 停止
        stop_auto_mode()
        stop()
    elif direction == 'auto':  # 啟用自動模式
        start_auto_mode()

    return jsonify({"status": "success", "action": direction})

@app.route('/control/hold', methods=['POST'])  # 按住按鍵控制
def control_hold():
    global auto_mode
    direction = request.json.get('direction')

    if direction == 'forward':  # 按住前進
        stop_auto_mode()
        move_forward()
    elif direction == 'stop':  # 鬆開停止
        stop_auto_mode()
        stop()

    return jsonify({"status": "success", "action": direction})

# ====================== 主程式啟動區域 ======================
if __name__ == '__main__':
    try:
        print("All.py script updated and running...")  # 程式啟動提示
        app.run(host='0.0.0.0', port=5000)
    except KeyboardInterrupt:  # 捕捉 Ctrl+C 退出
        GPIO.cleanup()  # 清理 GPIO
