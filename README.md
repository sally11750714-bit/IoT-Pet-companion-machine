專題功能簡述

本專案透過 Raspberry Pi 搭配 Flask 後端，結合 Flutter APP 進行遠端控制，實現以下功能：

1.機器人移動控制：
前進、後退、左轉、右轉等基本控制。
自動避障模式 (啟用紅外線感測器)。

2.雷射控制：
遠端開啟/關閉雷射指示燈。

3.投食裝置控制：
控制步進馬達進行投食動作。

4.視訊串流：
從 Raspberry Pi 中透過 MJPEG 格式串流視訊，實時顯示攝影機畫面。

安裝程式說明

壹.伺服器端 (Raspberry Pi)

硬體需求：
Raspberry Pi (測試版本: RPi 3/4)
ESP32-CAM (可選擇作為視訊串流裝置)
感測器及馬達模組 (依功能需求而定)

軟體需求：
Raspberry Pi OS (Buster 或 Bullseye 版本)
Python 3.7+
Flask
Flask-CORS
RPi.GPIO

安裝步驟：

1.系統環境設置
確保系統更新並安裝所需套件：
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install python3-pip python3-dev

2.安裝 Python 套件
pip3 install flask flask-cors RPi.GPIO

3.啟動 Flask 後端伺服器
將提供的程式碼保存為 app.py，運行程式：
python3 app.py
預設會啟動 HTTP 伺服器於 http://<Raspberry_IP>:5000。

4.視訊串流服務
使用外接鏡頭，在電腦端執行camera_1.py:
python3 camera_1.py
預設串流路徑：http://<鏡頭_IP>:5001/video_feed。

貳.前端 APP (Flutter)

環境需求：
Flutter SDK (版本: 3.10.0+)
Android Studio / VS Code (開發工具)
Android 設備或模擬器

安裝步驟：
1.安裝 Flutter
依據 Flutter 官方網站安裝 SDK：Flutter 安裝說明

2.下載本專案程式碼
將所有 Flutter 檔案儲存並確認 pubspec.yaml 內容正確。

3.安裝依賴
使用 Terminal 進入專案目錄，執行：
flutter pub get

4.執行 APP
將 APP 安裝到 Android 設備上：
flutter run

程式架構
Raspberry Pi (後端 Flask)
app.py：包含 GPIO 控制、Flask API 實現與自動避障程式邏輯。

Flutter APP (前端)

1.主程式 (main.dart)：
統一介面管理，並導入子頁面進行控制操作。

2.子頁面功能：
robot_control.dart：控制機器人前進/後退/轉向及啟動自動模式。
laser_control.dart：雷射裝置的開/關控制。
motor_control.dart：投食步進馬達控制功能。

3.影像串流：透過 StreamBuilder 監聽並呈現 Raspberry Pi 視訊串流。

4.依賴套件：
HTTP 請求通訊：http
影像處理及串流：Dart 自帶 Uint8List 支援。

執行畫面預覽
主畫面：包含機器人、雷射、步進馬達控制及視訊串流展示。
控制按鈕：通過按下按鈕可發送命令至 Flask 伺服器，遠端控制硬體設備。

結語
本專案透過 Flutter 進行圖形化介面設計，並藉由 Flask 伺服器與 Raspberry Pi 互動，使得遠端操控變得直觀且容易擴充。搭配自動避障及攝像頭視訊串流，為監控系統帶來便利性與即時回饋效果。
