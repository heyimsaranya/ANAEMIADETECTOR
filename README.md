# **Anemia Screening & Health Monitoring System**

This project is a **clinical-grade Flutter application** designed for non-invasive anemia screening. By combining **computer vision** (analyzing physiological sites) with **IoT sensor data**, the system provides a comprehensive, non-invasive health assessment.

---

### **🌟 Clinical Screening Methods**
* **Ocular Conjunctiva Analysis:** Captures and analyzes the pallor of the lower eyelid conjunctiva using specialized image processing.
* **Nail Bed & Palm Pallor Detection:** Visual assessment of peripheral perfusion and hemoglobin indicators via the `nail_capture` and `palm_capture` modules.
* **IoT Vital Monitoring:** Real-time **SpO2** and **Heart Rate** data acquisition via **ESP32/Arduino** and the **MAX30102** sensor.
* **Patient Questionnaire:** Structured data collection to supplement physiological markers for higher diagnostic accuracy.

### **🛠️ Technical Architecture**
* **Frontend:** Flutter (Mobile & Web)
* **State Management:** `Provider` / `ScanProvider` for real-time data flow and reactive UI updates.
* **Backend:** **Firebase** (Authentication & Cloud Firestore) for secure patient records.
* **Hardware Interface:** Serial communication support for **ESP32/Arduino** integration.
* **Deployment:** Optimized for high-performance hosting on **Vercel**.

### **📂 Key Project Modules**
* `lib/screens/`: Core diagnostic UI, including specialized camera capture screens for conjunctiva, nails, and palms.
* `lib/services/`: Manages `auth_service.dart` for security and `scan_provider.dart` for image/sensor data processing.
* `assets/`: Storage for medical reference images, custom icons, and typography.

---

### **🚀 Getting Started**

#### **Prerequisites**
* **Flutter SDK** (Latest Stable)
* **Node.js** (Required for Vercel CLI deployment)
* **ESP32/Arduino Hardware** for sensor-based features.

#### **Installation**
1.  **Clone & Install:**
    ```bash
    git clone https://github.com/your-username/anemia_app.git
    cd anemia_app
    flutter pub get
    ```
2.  **Run Locally:**
    ```bash
    flutter run
    ```

---

### **🌐 Web Deployment (Vercel)**
To push updates to your live production environment, use the following workflow:

1.  **Generate Release Build:**
    ```bash
    flutter build web --release
    ```
2.  **Deploy via CLI:**
    ```bash
    cd build/web
    vercel --prod --force
    ```

---

### **📄 Research & Authorship**
Developed as part of a **Biomedical Engineering** research initiative focusing on affordable, non-invasive diagnostic tools.

