#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <KWindowEffects>
#include <KWindowSystem>
#include <QRegion>
#include <QScreen>
#include <QWindow>
#include <iostream>
#include <QScrollBar>

#include "blur_config.h"


// Clamps the value n into the interval [low, high].
float constrain(float n, float low, float high) {
  return std::max(std::min(n, high), low);
}

// Linearly maps a value from the expected interval [start1, stop1] to [start2,
// stop2]. Implementation taken from p5.js
float map(float value, float start1, float stop1, float start2, float stop2,
          bool withinBounds = false) {
  float m = start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
  if (!withinBounds)
    return m;
  if (start2 < stop2)
    return constrain(value, start2, stop2);
  else
    return constrain(value, stop2, start2);
}

// Mixes the base color (light gray) with col at a certain percentage.
QColor mixColor(QColor col, double percentage) {
  QColor base = QColor(225, 225, 225);
  if (percentage > 1.0 || percentage < 0.0)
    return base;
  double base_percentage = 1.0 - percentage;
  unsigned int r1 = (int)((double)base.red() * base_percentage);
  unsigned int g1 = (int)((double)base.green() * base_percentage);
  unsigned int b1 = (int)((double)base.blue() * base_percentage);

  unsigned int r2 = (int)((double)col.red() * percentage);
  unsigned int g2 = (int)((double)col.green() * percentage);
  unsigned int b2 = (int)((double)col.blue() * percentage);

  return QColor(r1 + r2, g1 + g2, b1 + b2);
}

MainWindow::MainWindow(QSpinBox *spinbox, QSpinBox *spinboxg, QCheckBox *checkbox,
                       QSlider* hslider, QSlider* sslider, QSlider* vslider, QSlider* islider,
                       QLineEdit* custom, KCModule* config, QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow) {

  // Predefined style for the QSlider groove and handle.
  style = "QSlider::groove:horizontal {"
          "background-color: GRADIENT_HERE;"
          "height: 5px;"
          "position: absolute;"
          "}"

          "QSlider::handle:horizontal {"
          "    height: 3px;"
          "    width: 8px;"
          "    background: #f0f0f0;"
          "    border: 1px solid #707070;"
          "    border-radius: 2px;"
          "    margin: -6px 1px;"
          "}"

          "QSlider::handle:horizontal:hover { "
          "    background: #def2fc;"
          "}";

  background_style =
      "QWidget#centralwidget { background-color: qlineargradient(spread:pad, "
      "x1:0, y1:1, x2:0.0, y2:0, stop:0 rgba(0,0,0,0) stop:0.105 rgba(0,0,0,0) "
      "stop:0.106 ! }";

  ui->setupUi(this);
  preventChanges = true;
  cancelChanges = true;

  kcfg_AccentColorName = spinbox;
  kcfg_EnableTransparency = checkbox;
  kcfg_AeroIntensity = islider;
  kcfg_AeroHue = hslider;
  kcfg_AeroSaturation = sslider;
  kcfg_AeroBrightness = vslider;
  kcfg_CustomColor = custom;
  kcfg_AccentColorGroup = spinboxg;
  config_parent = config;

  if(kcfg_AccentColorGroup->value() >= colorGroups.size()) {
      kcfg_AccentColorGroup->setValue(0);
  }

  ui->kcfg_EnableTransparency->setChecked(checkbox->isChecked());
  // Setting attributes which will allow the window to have a transparent
  // blurred background.
  this->setObjectName("main");
  this->setAttribute(Qt::WA_TranslucentBackground, true);
  this->setAttribute(Qt::WA_NoSystemBackground, true);
  this->setStyleSheet(
    "QMainWindow#main {"
    "background: transparent;"
    "}"
  );
  ui->centralwidget->setStyleSheet(
    "QWidget#centralwidget {"
    "background: transparent;"
    "}"
  );

  footer_color = QWidget::palette().window().color();
  background_color = QWidget::palette().base().color();

  QColor border_color = QWidget::palette().midlight().color();

  // Using QToolBar to make the entire extended titlebar draggable
  QLabel *titleLabel = new QLabel("<html><head/><body><p><span style=\" font-size:12pt;\">Change the color of your window borders, Start menu, and taskbar</span></p></body></html>");
  QGraphicsGlowEffect *glow_effect = new QGraphicsGlowEffect();
  glow_effect->setStrength(5);
  glow_effect->setBlurRadius(8);
  titleLabel->setGraphicsEffect(glow_effect);
  titleLabel->setIndent(12);
  titleLabel->setMargin(2);
  ui->toolBar->addWidget(titleLabel);
  ui->toolBar->setContextMenuPolicy(Qt::PreventContextMenu);
  ui->toolBar->toggleViewAction()->setEnabled(false);

  ui->scrollAreaWidgetContents->setContentsMargins(128, 12, 128, 12);
  ui->scrollArea->verticalScrollBar()->installEventFilter(this);

  QColor light_text_color = QWidget::palette().brush(QPalette::Disabled, QPalette::PlaceholderText).color();
  ui->colorPaletteLabel->setStyleSheet(
    "QLabel#colorPaletteLabel {"
    "color: " + light_text_color.name() + ";"
    "}"
  );

  ui->footer->setStyleSheet(
    "QWidget#footer {"
    "background: " + footer_color.name() + ";"
    "border-top: 1px solid " + border_color.name() + ";"
    "}"
  );
  // Setting up more UI stuff.

  ui->colorMixerGroupBox->setVisible(false);
  // Template string defining the CSS style for the hue slider.
  hue_gradient = "qlineargradient(x1: 0, y1: 1, x2: 1, y2: 1, stop: 0 #FF0000, "
                 "stop: 0.167 #FFFF00, stop: 0.33 #00FF00, stop: 0.5 #00FFFF, "
                 "stop: 0.667 #0000FF, stop: 0.833 #FF00FF, stop: 1 #FF0000)";
  ui->hue_Slider->setStyleSheet(
      QString(style).replace("GRADIENT_HERE", hue_gradient));
  // Likewise for the saturation and brightness sliders.
  saturation_gradient =
      "qlineargradient(x1: 0, y1: 1, x2: 1, y2: 1, stop: 0 #FFFFFF, stop: 1 " +
      QColor::fromHsl(ui->hue_Slider->value(), 255, 128).name(QColor::HexRgb) +
      ")";
  brightness_gradient =
      "qlineargradient(x1: 0, y1: 1, x2: 1, y2: 1, stop: 0 #000000, stop: 1 " +
      QColor::fromHsl(ui->hue_Slider->value(), 255, 128).name(QColor::HexRgb) +
      ")";
  ui->saturation_Slider->setStyleSheet(
      QString(style).replace("GRADIENT_HERE", saturation_gradient));
  ui->Lightness_Slider->setStyleSheet(
      QString(style).replace("GRADIENT_HERE", brightness_gradient));

  ui->hue_label->setText(QString::number(ui->hue_Slider->value()));
  ui->alpha_label->setText(QString::number(ui->alpha_slider->value()));
  ui->saturation_label->setText(
      QString::number(ui->saturation_Slider->value()));
  ui->brightness_label->setText(QString::number(ui->Lightness_Slider->value()));

  groupedActions = new QActionGroup(nullptr);
  groupedActions->setExclusive(true);
  // Populate QMenu with groups
  for(int i = 0; i < colorGroups.size(); i++) {
    QAction *action = new QAction(colorGroups[i]);
    action->setCheckable(true);
    action->setActionGroup(groupedActions);
    groupContextMenu.addAction(action);
  }
  connect(&groupContextMenu, &QMenu::triggered, this, &MainWindow::on_colorGroup_triggered);
  connect(ui->colorGroupLabel, &QPushButton::clicked, this, &MainWindow::on_colorGroupLabel_clicked);
  connect(ui->kcfg_AccentColorGroup, &QSpinBox::valueChanged, this, &MainWindow::on_colorGroupSpinBox_valueChanged);

  ui->kcfg_AccentColorGroup->setValue(kcfg_AccentColorGroup->value());
  ui->kcfg_AccentColorGroup->setVisible(false);
  groupedActions->actions()[kcfg_AccentColorGroup->value()]->setChecked(true);

  for (int i = 0; i < values.size(); i++) {
    QStringList temp = values[i].split("-");
    predefined_colors.push_back(
        ColorWindow(temp[1], QColor("#" + temp[0]), ui->groupBox, i, temp[2].toInt()));
  }
  // By default, the selected color is Sky.
  selected_color = kcfg_AccentColorName->value();

  // Creating a FlowLayout and storing all the colors there.
  colorLayout = new FlowLayout(ui->groupBox);

  for (unsigned int i = 0; i < predefined_colors.size(); i++) {
    colorLayout->addWidget(predefined_colors[i].getFrame());
    connect(predefined_colors[i].getFrameButton(), SIGNAL(clicked()), this,
            SLOT(on_colorWindow_Clicked()));
  }
  colorLayout->setAlignment(Qt::AlignHCenter | Qt::AlignVCenter);

  predefined_colors[0].setColor(QColor::fromString(kcfg_CustomColor->text()));
  predefined_colors[selected_color].getFrameButton()->setSelected(true);
  changeColor(selected_color);

  applyFilter();

  preventChanges = false;
}

void MainWindow::applyFilter()
{
    for(int i = 0; i < predefined_colors.size(); i++)
    {
        predefined_colors[i].setVisible(predefined_colors[i].colorGroup() == ui->kcfg_AccentColorGroup->value());
    }
}

void MainWindow::on_colorGroupSpinBox_valueChanged(int value)
{
  QString actionText = groupedActions->actions()[value]->text();
  ui->colorGroupLabel->setText(actionText + " ⏷");
  applyFilter();
}

MainWindow::~MainWindow() {
  for (unsigned int i = 0; i < predefined_colors.size(); i++) {
    predefined_colors[i].clear();
  }
  delete ui;
}
void MainWindow::on_colorGroupLabel_clicked()
{
  auto menuWidth = groupContextMenu.sizeHint().width();
  auto position = ui->colorGroupLabel->mapToGlobal(QPoint(0,0));
  position += QPoint(ui->colorGroupLabel->width(), ui->colorGroupLabel->height());
  position -= QPoint(menuWidth, 0);
  groupContextMenu.popup(position);
}

void MainWindow::on_colorGroup_triggered(QAction *action)
{
  int index = groupedActions->actions().indexOf(action);
  ui->kcfg_AccentColorGroup->setValue(index);
}

bool MainWindow::eventFilter(QObject *o, QEvent *e)
{
    if(o == ui->scrollArea->verticalScrollBar())
    {
        if(e->type() == QEvent::Show || e->type() == QEvent::Hide)
        {
            ui->scrollAreaWidgetContents->setContentsMargins(128 - (e->type() == QEvent::Show ? ui->scrollArea->verticalScrollBar()->width() : 0), 12, 128, 12);
        }
    }
    return QMainWindow::eventFilter(o, e);
}
void MainWindow::on_windowActiveChanged()
{
    if(window_handle) {
        window_handle->setIcon(QIcon::fromTheme("preferences-desktop-theme-global"));
        ui->frame->setStyleSheet(QString("QFrame#frame {\n") +
        "border-image: url(\":/svgs/inner_borders_" + (window_handle->isActive() ? QStringLiteral("active") : QStringLiteral("inactive")) + ".png\") 2 2 2 2;\n" +
        "border-top: 2px transparent;\n"   +
        "border-left: 2px transparent;\n"  +
        "border-bottom: 2px transparent;\n"+
        "border-right: 2px transparent;\n" +
        "background-color: " + background_color.name() + ";\n" +
        "background-clip: padding;\n" +
        "}\n");
    }
}
void MainWindow::showEvent(QShowEvent *event)
{
    if(this->windowHandle()) {
        KWindowEffects::enableBlurBehind(this->windowHandle(), true, QRegion(0,0, 0, 0));
        window_handle = this->windowHandle();
        connect(window_handle, SIGNAL(activeChanged()), this, SLOT(on_windowActiveChanged()));
    }

}
/*
 * Returns the currently set color. Depending on the transparency settings, the
 * alpha value will either be directly used as the transparency value, or it
 * will be used to define the saturation of the color.
 */
QColor MainWindow::exportColor() {
  if (ui->kcfg_EnableTransparency->isChecked()) {
    // The color intensity doesn't actually make the alpha component fully
    // transparent or opaque.
    double alpha_dec = map(ui->alpha_slider->value(), 0, 255, 0.1f, 0.8f);
    QColor c = predefined_colors[selected_color].getColor();
    c.setAlphaF(alpha_dec);
    return c;
  } else {
    return mixColor(predefined_colors[selected_color].getColor(),
                    ui->alpha_slider->value() / 255.0f);
  }
}

// Resets this window to default values.
// Used when closing the window without applying changes.
void MainWindow::resetToDefault() {
  int intensity  = kcfg_AeroIntensity->value();
  int hue        = kcfg_AeroHue->value();
  int saturation = kcfg_AeroSaturation->value();
  int brightness = kcfg_AeroBrightness->value();
  // resetting the custom color
  predefined_colors[0].setColor(QColor::fromString(kcfg_CustomColor->text()));
  predefined_colors[selected_color].getFrameButton()->setSelected(false);
  changeColor(kcfg_AccentColorName->value(), true);
  predefined_colors[kcfg_AccentColorName->value()].getFrameButton()->setSelected(true);
  ui->kcfg_AccentColorGroup->setValue(kcfg_AccentColorGroup->value());
  groupedActions->actions()[kcfg_AccentColorGroup->value()]->setChecked(true);

  //preventChanges = true;
  ui->kcfg_EnableTransparency->setChecked(kcfg_EnableTransparency->isChecked());
  //preventChanges = false;
}

void MainWindow::applyTemporarily() {
  KWin::BlurEffectConfig *conf = (KWin::BlurEffectConfig *)config_parent;

  int intensity;
  if(predefined_colors[selected_color].getColor().alpha() < 26) intensity = predefined_colors[selected_color].getColor().alpha();
  else intensity = ui->alpha_slider->value();
  //int intensity  = ui->alpha_slider->value();
  int hue        = ui->hue_Slider->value();
  int saturation = ui->saturation_Slider->value();
  int brightness = ui->Lightness_Slider->value();
  conf->writeToMemory(hue, saturation, brightness, intensity, ui->kcfg_EnableTransparency->isChecked(), true);
}

// Changes the color between the custom and any of the predefined values.
void MainWindow::changeColor(int index, bool apply) {
  ui->color_name_label->setText("Current color: " +
                                predefined_colors[index].getName());
  selected_color = index;
  preventChanges = true;
  ui->hue_Slider->setValue(predefined_colors[index].getColor().hslHue());
  ui->saturation_Slider->setValue(
      predefined_colors[index].getColor().hsvSaturationF()*100.0f);
  ui->Lightness_Slider->setValue(predefined_colors[index].getColor().valueF()*100.0f);
  ui->alpha_slider->setValue(predefined_colors[index].getColor().alpha());
  preventChanges = false;
  if (apply)
    applyTemporarily();
}

// This event fires when a color from the FlowLayout is clicked.
void MainWindow::on_colorWindow_Clicked() {
  predefined_colors[selected_color].getFrameButton()->setSelected(false);
  int index = sender()->objectName().split("_")[1].toInt();

  predefined_colors[index].getFrameButton()->setSelected(true);
  changeColor(index);
}

// Changes the custom color, this method executes whenever the sliders are
// moved.
void MainWindow::changeCustomColor(bool apply) {
  if (!preventChanges) {
    predefined_colors[selected_color].getFrameButton()->setSelected(false);
    selected_color = 0;
    predefined_colors[0].getFrameButton()->setSelected(true);
    ui->color_name_label->setText("Current color: Custom");
    QColor c;
    c.setHsv(ui->hue_Slider->value(), ui->saturation_Slider->value()*2.55f,
             ui->Lightness_Slider->value()*2.55f, ui->alpha_slider->value());
    predefined_colors[selected_color].setColor(c);
    if (apply)
      applyTemporarily();
  }
}

// Toggles the visibility of the group box containing the color sliders.
void MainWindow::on_colorMixerLabel_linkActivated(const QString &link) {
  ui->colorMixerGroupBox->setVisible(!ui->colorMixerGroupBox->isVisible());
  ui->colorMixerLabel->setText(ui->colorMixerGroupBox->isVisible()
                                   ? "<a style=\"color: #0066D4\" href=\"no\">Hide color mixer</a>"
                                   : "<a style=\"color: #0066D4\" href=\"no\">Show color mixer</a>");
}

// Updates the color sliders and updates the custom color.
void MainWindow::on_hue_Slider_valueChanged(int value) {
  ui->hue_label->setText(QString::number(ui->hue_Slider->value()));
  saturation_gradient =
      "qlineargradient(x1: 0, y1: 1, x2: 1, y2: 1, stop: 0 #FFFFFF, stop: 1 " +
      QColor::fromHsl(ui->hue_Slider->value(), 255, 128).name(QColor::HexRgb) +
      ")";
  brightness_gradient =
      "qlineargradient(x1: 0, y1: 1, x2: 1, y2: 1, stop: 0 #000000, stop: 1 " +
      QColor::fromHsl(ui->hue_Slider->value(), 255, 128).name(QColor::HexRgb) +
      ")";
  ui->saturation_Slider->setStyleSheet(
      QString(style).replace("GRADIENT_HERE", saturation_gradient));
  ui->Lightness_Slider->setStyleSheet(
      QString(style).replace("GRADIENT_HERE", brightness_gradient));
  changeCustomColor();
}

void MainWindow::on_pushButton_3_clicked() { this->close(); }

void MainWindow::on_saturation_Slider_valueChanged(int value) {
  ui->saturation_label->setText(
      QString::number(ui->saturation_Slider->value()));
  changeCustomColor();
}

void MainWindow::on_Lightness_Slider_valueChanged(int value) {
  ui->brightness_label->setText(QString::number(ui->Lightness_Slider->value()));
  changeCustomColor();
}

void MainWindow::on_alpha_slider_valueChanged(int value) {
  ui->alpha_label->setText(QString::number(ui->alpha_slider->value()));
  changeCustomColor();
}

void MainWindow::applyChanges() {
  cancelChanges = false;
  kcfg_CustomColor->setText(predefined_colors[0].getColor().name(QColor::HexArgb));
  kcfg_AccentColorName->setValue(selected_color);
  kcfg_EnableTransparency->setChecked(ui->kcfg_EnableTransparency->isChecked());
  if(predefined_colors[selected_color].getColor().alpha() < 26) kcfg_AeroIntensity->setValue(predefined_colors[selected_color].getColor().alpha());
  else kcfg_AeroIntensity->setValue(ui->alpha_slider->value());
  kcfg_AeroHue->setValue(ui->hue_Slider->value());
  kcfg_AeroSaturation->setValue(ui->saturation_Slider->value());
  kcfg_AeroBrightness->setValue(ui->Lightness_Slider->value());
  kcfg_AccentColorGroup->setValue(predefined_colors[selected_color].colorGroup());

  KWin::BlurEffectConfig *conf = (KWin::BlurEffectConfig *)config_parent;
  conf->save();
}

// This function runs whenever the window is being closed.
// I wrote this at 3 AM it's probably overengineered but it works
// I'll simplify this down the line later
void MainWindow::closeEvent(QCloseEvent *event) {
  int intensity  = kcfg_AeroIntensity->value();
  int hue        = kcfg_AeroHue->value();
  int saturation = kcfg_AeroSaturation->value();
  int brightness = kcfg_AeroBrightness->value();
  KWin::BlurEffectConfig *conf = (KWin::BlurEffectConfig *)config_parent;
  conf->writeToMemory(hue, saturation, brightness, intensity,
                      kcfg_EnableTransparency->isChecked(), cancelChanges);
  resetToDefault();
  QMainWindow::closeEvent(event);
}
void MainWindow::on_apply_Button_clicked() { applyChanges(); }

void MainWindow::on_cancel_Button_clicked() { this->close(); }

void MainWindow::on_saveChanges_Button_clicked() {
  applyChanges();
  this->close();
}

void MainWindow::on_kcfg_EnableTransparency_stateChanged(int arg1) {
  if (!preventChanges)
    applyTemporarily();
}
