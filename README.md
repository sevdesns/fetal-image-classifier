# Fetal Ultrasound Image Classifier and Measurement System

A comprehensive MATLAB-based system for automated classification and biometric measurement of fetal ultrasound images using deep learning and computer vision techniques.

## Overview

This project provides an end-to-end solution for analyzing fetal ultrasound images, featuring:
- **Multi-class image classification** using transfer learning with pre-trained CNNs
- **Advanced denoising** with multiple filter algorithms
- **Automatic biometric measurements** (Femur Length, Head Circumference)
- **Scale bar detection** for real-world measurement calibration
- **Modern graphical user interface** built with MATLAB App Designer

## Features

### 🧠 Deep Learning Classification
- Transfer learning with **ResNet18** or **MobileNetV2**
- Multi-class classification of fetal ultrasound planes:
  - Fetal abdomen
  - Fetal brain
  - Fetal femur
  - Fetal thorax
- Data augmentation for improved generalization
- Stratified train/validation split (80/20)

### 🎨 Image Processing
- **Denoising Filters:**
  - Median Filter (7×7)
  - Wiener Filter (5×5)
  - Gaussian Filter (σ=2.0)
  - Bilateral Filter (edge-preserving)
- **Contrast Enhancement:**
  - CLAHE (Contrast Limited Adaptive Histogram Equalization)
- **Edge Detection:**
  - Canny edge detection with adaptive thresholds

### 📏 Automatic Measurements
- **Femur Length (FL):**
  - Canny edge detection
  - Hough transform for line detection
  - Automatic longest line identification
  - Pixel-to-millimeter conversion
  
- **Head Circumference (HC):**
  - Contour detection and analysis
  - Ellipse fitting using least squares
  - Ramanujan's approximation formula for perimeter calculation
  - Automatic measurement in centimeters

### 📐 Scale Bar Detection
- Automatic detection of scale bars in the upper-right region
- Real-world calibration for accurate measurements
- Fallback to pixel-based estimation when scale bar is not detected

### 🖥️ User Interface
- Modern, intuitive GUI with sidebar navigation
- Real-time image processing and visualization
- Interactive filter selection and parameter adjustment
- Measurement reports with confidence indicators

## Project Structure

```
fetal_image_classifier/
├── FetalImageAnalyzer.m              # Main GUI application
├── Stage1_LoadDataset.m                # Dataset loading and preprocessing
├── Stage2_Denoising.m                 # Denoising module with 4 filters
├── Stage3_CNNTraining.m               # CNN training with transfer learning
├── Stage4_ImageProcessing.m           # Image enhancement and edge detection
├── Stage5_AutomaticMeasurements.m     # Automatic measurement module
├── detectScaleBar.m                   # Scale bar detection algorithm
├── calculatePixelToMM.m               # Pixel-to-millimeter conversion
├── fitEllipse.m                       # Ellipse fitting for HC measurement
├── trained_model.mat                  # Pre-trained CNN model
└── Classification/
    ├── image_label.csv                # Image labels and metadata
    ├── images/                        # Training images (~1646 images)
    └── External Test images/          # Test images (~40 images)
```

## Requirements

### MATLAB Version
- **MATLAB R2020b** or later

### Required Toolboxes
- **Deep Learning Toolbox** (for CNN training and inference)
- **Image Processing Toolbox** (for image enhancement and analysis)
- **Statistics and Machine Learning Toolbox** (for data analysis)

### Hardware Recommendations
- **GPU**: NVIDIA GPU with CUDA support (optional, for faster training)
- **RAM**: 8 GB minimum, 16 GB recommended
- **Storage**: ~2 GB for dataset and models

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sevdesns/fetal-image-classifier.git
   cd fetal-image-classifier
   ```

2. **Verify MATLAB toolboxes:**
   ```matlab
   ver  % Check installed toolboxes
   ```

3. **Ensure dataset is in place:**
   - Place training images in `Classification/images/`
   - Place test images in `Classification/External Test images/`
   - Ensure `Classification/image_label.csv` exists

## Usage

### Quick Start

#### 1. Load Dataset
```matlab
Stage1_LoadDataset
```
This script:
- Loads image labels from CSV
- Creates train/test splits
- Displays class distribution statistics
- Saves dataset information to workspace

#### 2. Train CNN Model
```matlab
Stage3_CNNTraining
```
This script:
- Loads pre-trained ResNet18 or MobileNetV2
- Performs transfer learning
- Trains for 40 epochs with data augmentation
- Saves model to `trained_model.mat`
- Displays training progress and confusion matrix

#### 3. Launch GUI Application
```matlab
app = FetalImageAnalyzer
```
The GUI provides:
- Image loading and visualization
- Interactive denoising with filter selection
- Real-time classification with confidence scores
- Image processing tools (CLAHE, edge detection)
- Automatic measurements with visual feedback

### Advanced Usage

#### Denoising Analysis
```matlab
Stage2_Denoising
```
Compares four denoising filters with quantitative metrics:
- PSNR (Peak Signal-to-Noise Ratio)
- SNR (Signal-to-Noise Ratio)
- SSIM (Structural Similarity Index)
- Noise reduction percentage

#### Image Processing
```matlab
Stage4_ImageProcessing
```
Applies:
- Canny edge detection
- CLAHE contrast enhancement
- Histogram analysis
- Contrast metrics calculation

#### Automatic Measurements
```matlab
Stage5_AutomaticMeasurements
```
Performs:
- Scale bar detection
- Femur length measurement
- Head circumference measurement
- Results visualization

## Technical Details

### Classification Architecture
- **Base Model**: ResNet18 (default) or MobileNetV2
- **Input Size**: 224×224×3 (RGB)
- **Training**: Adam optimizer, initial learning rate 0.001
- **Augmentation**: Rotation (±15°), translation, scaling, reflection
- **Regularization**: L2 (λ=0.0001), dropout

### Measurement Algorithms

#### Femur Length
1. **Preprocessing**: Wiener filter (5×5) for noise reduction
2. **Edge Detection**: Canny with thresholds [0.1, 0.2], σ=1.5
3. **Line Detection**: Hough transform
   - Rho resolution: 1 pixel
   - Theta resolution: 0.5°
   - Minimum line length: 50 pixels
4. **Measurement**: Longest detected line → pixel length → mm/cm

#### Head Circumference
1. **Preprocessing**: Wiener filter (5×5)
2. **Edge Detection**: Canny with thresholds [0.05, 0.15], σ=1.0
3. **Contour Analysis**: Largest contour detection
4. **Ellipse Fitting**: Least squares method
5. **Perimeter Calculation**: Ramanujan's approximation
   ```
   P ≈ π × [3(a+b) - √((3a+b)(a+3b))]
   ```
   where a, b are semi-major and semi-minor axes

### Scale Bar Detection
- **Region of Interest**: Upper-right 30% width × 20% height
- **Method**: Binary thresholding + morphological operations
- **Selection Criteria**: Aspect ratio, orientation, size
- **Calibration**: Assumes 1 cm scale bar length

## Performance Metrics

### Classification
- Validation accuracy varies by dataset
- Per-class accuracy reported in training output
- Confusion matrix visualization

### Denoising
- **Best Performance**: Typically Wiener or Gaussian filter
- **Noise Reduction**: 25-40% variance reduction
- **PSNR**: 20-30 dB typical improvement

### Measurements
- **Accuracy**: Depends on image quality and scale bar presence
- **Real Measurements**: When scale bar detected
- **Estimated Measurements**: Pixel-based fallback (marked as [ESTIMATED])

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is developed for educational and research purposes.

## Author

**Sevde Nur Susancak**

- GitHub: [@sevdesns](https://github.com/sevdesns)
- Profile: [https://github.com/sevdesns](https://github.com/sevdesns)

## Acknowledgments

- MATLAB Deep Learning Toolbox team
- Medical imaging research community
- Open-source computer vision libraries

## Citation

If you use this project in your research, please cite:

```bibtex
@software{fetal_image_classifier,
  author = {Susancak, Sevde Nur},
  title = {Fetal Ultrasound Image Classifier and Measurement System},
  year = {2025},
  url = {https://github.com/sevdesns/fetal-image-classifier}
}
```

## Future Improvements

- [ ] Support for additional measurement types (BPD, AC, etc.)
- [ ] Real-time video processing
- [ ] Integration with DICOM format
- [ ] Web-based interface
- [ ] Mobile app version
- [ ] Multi-GPU training support

---

**Note**: This software is intended for research and educational purposes. For clinical use, please ensure proper validation and regulatory compliance.
