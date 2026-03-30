# **Anemia Screening & Health Monitoring System**

A **clinical-grade Flutter application** for **non-invasive anemia screening** and real-time health monitoring. This system integrates **computer vision analysis** of physiological sites with **IoT sensor data** to provide a comprehensive health assessment.

---

### **🌟 Clinical Screening Features**

* **Conjunctiva Analysis:** Detects pallor in the lower eyelid to estimate hemoglobin levels using advanced image processing techniques.
* **Nail Bed & Palm Pallor Detection:** Evaluates peripheral perfusion and hemoglobin indicators via the `nail_capture` and `palm_capture` modules.
* **IoT-Based Vital Monitoring:** Real-time acquisition of **SpO2** and **Heart Rate** using **ESP32/Arduino** paired with the **MAX30102** sensor.
* **Patient Questionnaire:** Collects structured patient data to enhance diagnostic accuracy alongside physiological assessments.

---

### **🛠️ Technical Architecture**

* **Frontend:** Flutter (supports Mobile & Web platforms)
* **State Management:** `Provider` / `ScanProvider` ensures real-time data flow and responsive UI updates.
* **Backend:** **Firebase Authentication & Cloud Firestore** for secure, scalable patient data storage.
* **Hardware Integration:** Supports serial communication with **ESP32/Arduino** for sensor-based measurements.
* **Deployment:** Optimized for high-performance hosting on **Vercel**.

---

### **📂 Project Structure**

* **`lib/screens/`** – Core diagnostic UI, including camera capture modules for conjunctiva, nails, and palms.
* **`lib/services/`** – Includes `auth_service.dart` for authentication and `scan_provider.dart` for image and sensor data processing.
* **`assets/`** – Stores medical reference images, custom icons, and typography resources.

---

### **🚀 Getting Started**

#### **Prerequisites**

* **Flutter SDK** (latest stable version)
* **Node.js** (required for Vercel deployment)
* **ESP32/Arduino hardware** (for sensor integration)

#### **Installation**

1. **Clone the repository & install dependencies**

```bash
git clone https://github.com/your-username/anemia_app.git
cd anemia_app
flutter pub get
```

2. **Run the application locally**

```bash
flutter run
```

---

### **🌐 Web Deployment (Vercel)**

1. **Build the Flutter web release**

```bash
flutter build web --release
```

2. **Deploy to Vercel**

```bash
cd build/web
vercel --prod --force
```

---


