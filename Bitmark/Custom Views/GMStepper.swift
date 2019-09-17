//
//  GMStepper.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

/**
 GMStepper: A stepper with a sliding label in the middle. Pan the label or tap the buttons.
 Reference: https://github.com/gmertk/GMStepper
 Customize to fix our requirement: Replace Label with Textfield
 - Usage: in Register Asset Form
 */
@IBDesignable public class GMStepper: UIControl {

  /// Current value of the stepper. Defaults to 0.
  @IBInspectable public var value: Double = 0 {
    didSet {
      value = min(maximumValue, max(minimumValue, value))

      textfield.text = formattedValue

      if oldValue != value {
        sendActions(for: .valueChanged)
      }
    }
  }

  private var formattedValue: String? {
    let isInteger = Decimal(value).exponent >= 0

    // If we have items, we will display them as steps
    if isInteger && stepValue == 1.0 && !items.isEmpty {
      return items[Int(value)]
    } else {
      return formatter.string(from: NSNumber(value: value))
    }
  }

  /// Minimum value. Must be less than maximumValue. Defaults to 0.
  @IBInspectable public var minimumValue: Double = 0 {
    didSet {
      value = min(maximumValue, max(minimumValue, value))
    }
  }

  /// Maximum value. Must be more than minimumValue. Defaults to 100.
  @IBInspectable public var maximumValue: Double = 100 {
    didSet {
      value = min(maximumValue, max(minimumValue, value))
    }
  }

  /// Step/Increment value as in UIStepper. Defaults to 1.
  @IBInspectable public var stepValue: Double = 1 {
    didSet {
      setupNumberFormatter()
    }
  }

  /// The same as UIStepper's autorepeat. If true, holding on the buttons or keeping the pan gesture alters the value repeatedly. Defaults to true.
  @IBInspectable public var autorepeat: Bool = true

  /// If the value is integer, it is shown without floating point.
  @IBInspectable public var showIntegerIfDoubleIsInteger: Bool = true {
    didSet {
      setupNumberFormatter()
    }
  }

  /// Text on the left button. Be sure that it fits in the button. Defaults to "−".
  @IBInspectable public var leftButtonText: String = "−" {
    didSet {
      leftButton.setTitle(leftButtonText, for: .normal)
    }
  }

  /// Text on the right button. Be sure that it fits in the button. Defaults to "+".
  @IBInspectable public var rightButtonText: String = "+" {
    didSet {
      rightButton.setTitle(rightButtonText, for: .normal)
    }
  }

  /// Text color of the buttons. Defaults to white.
  @IBInspectable public var buttonsTextColor: UIColor = .azureRadiance {
    didSet {
      for button in [leftButton, rightButton] {
        button.setTitleColor(buttonsTextColor, for: .normal)
      }
    }
  }

  @IBInspectable public var boxBorderColor: UIColor = .mainBlueColor {
    didSet {
      for button in [leftButton, rightButton] {
        button.borderColor = boxBorderColor
      }
      textfield.borderColor = boxBorderColor
    }
  }

  let boxBorderWidth: CGFloat = 1.0

  /// Background color of the buttons. Defaults to dark blue.
  @IBInspectable public var buttonsBackgroundColor: UIColor = .white {
    didSet {
      for button in [leftButton, rightButton] {
        button.backgroundColor = buttonsBackgroundColor
      }
      backgroundColor = buttonsBackgroundColor
    }
  }

  /// Font of the buttons. Defaults to AvenirNext-Bold, 20.0 points in size.
  @objc public var buttonsFont = UIFont(name: "AvenirNext-Bold", size: 20.0)! {
    didSet {
      for button in [leftButton, rightButton] {
        button.titleLabel?.font = buttonsFont
      }
    }
  }

  /// Text color of the middle label. Defaults to white.
  @IBInspectable public var labelTextColor: UIColor = UIColor.black {
    didSet {
      textfield.textColor = labelTextColor
    }
  }

  /// Text color of the middle label. Defaults to lighter blue.
  @IBInspectable public var labelBackgroundColor: UIColor = .white {
    didSet {
      textfield.backgroundColor = labelBackgroundColor
    }
  }

  /// Font of the middle label. Defaults to AvenirNext-Bold, 25.0 points in size.
  @objc public var labelFont = UIFont(name: Constant.andaleMono, size: 13.0)! {
    didSet {
      textfield.font = labelFont
    }
  }
  /// Corner radius of the middle label. Defaults to 0.
  @IBInspectable public var labelCornerRadius: CGFloat = 0 {
    didSet {
      textfield.layer.cornerRadius = labelCornerRadius

    }
  }

  /// Percentage of the middle label's width. Must be between 0 and 1. Defaults to 0.5. Be sure that it is wide enough to show the value.
  @IBInspectable public var labelWidthWeight: CGFloat = 0.5 {
    didSet {
      labelWidthWeight = min(1, max(0, labelWidthWeight))
      setNeedsLayout()
    }
  }

  /// Color of the flashing animation on the buttons in case the value hit the limit.
  @IBInspectable public var limitHitAnimationColor: UIColor = UIColor(red: 0.26, green: 0.6, blue: 0.87, alpha: 1)

  /// Formatter for displaying the current value
  let formatter = NumberFormatter()

  /**
   Width of the sliding animation. When buttons clicked, the middle label does a slide animation towards to the clicked button. Defaults to 5.
   */
  let labelSlideLength: CGFloat = 2

  /// Duration of the sliding animation
  let labelSlideDuration = TimeInterval(0.1)

  /// Duration of the animation when the value hits the limit.
  let limitHitAnimationDuration = TimeInterval(0.1)

  lazy var leftButton: UIButton = {
    let button = UIButton()
    button.setTitle(self.leftButtonText, for: .normal)
    button.setTitleColor(self.buttonsTextColor, for: .normal)
    button.backgroundColor = self.buttonsBackgroundColor
    button.titleLabel?.font = self.buttonsFont
    button.borderColor = boxBorderColor
    button.borderWidth = boxBorderWidth
    button.addTarget(self, action: #selector(GMStepper.leftButtonTouchDown), for: .touchDown)
    button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpInside)
    button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpOutside)
    button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchCancel)
    return button
  }()

  lazy var rightButton: UIButton = {
    let button = UIButton()
    button.setTitle(self.rightButtonText, for: .normal)
    button.setTitleColor(self.buttonsTextColor, for: .normal)
    button.backgroundColor = self.buttonsBackgroundColor
    button.titleLabel?.font = self.buttonsFont
    button.borderColor = boxBorderColor
    button.borderWidth = boxBorderWidth
    button.addTarget(self, action: #selector(GMStepper.rightButtonTouchDown), for: .touchDown)
    button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpInside)
    button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpOutside)
    button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchCancel)
    return button
  }()

  lazy var textfield: UITextField = {
    let textfield = UITextField()
    textfield.textAlignment = .center
    textfield.text = formattedValue
    textfield.textColor = self.labelTextColor
    textfield.backgroundColor = self.labelBackgroundColor
    textfield.borderColor = boxBorderColor
    textfield.borderWidth = boxBorderWidth
    textfield.keyboardType = .numberPad
    textfield.returnKeyType = .done
    textfield.font = self.labelFont
    textfield.layer.cornerRadius = self.labelCornerRadius
    textfield.layer.masksToBounds = true
    textfield.isUserInteractionEnabled = true
    let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(GMStepper.handlePan))
    panRecognizer.maximumNumberOfTouches = 1
    textfield.addGestureRecognizer(panRecognizer)
    textfield.addTarget(self, action: #selector(GMStepper.typeTextfield), for: .editingChanged)
    textfield.addTarget(self, action: #selector(GMStepper.typeTextfieldDidEnd), for: .editingDidEnd)
    return textfield
  }()

  var labelOriginalCenter: CGPoint!
  var labelMaximumCenterX: CGFloat!
  var labelMinimumCenterX: CGFloat!

  enum LabelPanState {
    case stable, hitRightEdge, hitLeftEdge
  }
  var panState = LabelPanState.stable

  enum StepperState {
    case stable, shouldIncrease, shouldDecrease
  }
  var stepperState = StepperState.stable {
    didSet {
      if stepperState != .stable {
        updateValue()
        if autorepeat {
          scheduleTimer()
        }
      }
    }
  }

  @objc public var items: [String] = [] {
    didSet {
      textfield.text = formattedValue
    }
  }

  /// Timer used for autorepeat option
  var timer: Timer?

  /** When UIStepper reaches its top speed, it alters the value with a time interval of ~0.05 sec.
   The user pressing and holding on the stepper repeatedly:
   - First 2.5 sec, the stepper changes the value every 0.5 sec.
   - For the next 1.5 sec, it changes the value every 0.1 sec.
   - Then, every 0.05 sec.
   */
  let timerInterval = TimeInterval(0.05)

  /// Check the handleTimerFire: function. While it is counting the number of fires, it decreases the mod value so that the value is altered more frequently.
  var timerFireCount = 0
  var timerFireCountModulo: Int {
    if timerFireCount > 80 {
      return 1 // 0.05 sec * 1 = 0.05 sec
    } else if timerFireCount > 50 {
      return 2 // 0.05 sec * 2 = 0.1 sec
    } else {
      return 10 // 0.05 sec * 10 = 0.5 sec
    }
  }

  @objc required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  @objc public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  fileprivate func setup() {
    addSubview(leftButton)
    addSubview(rightButton)
    addSubview(textfield)

    backgroundColor = buttonsBackgroundColor
    layer.cornerRadius = cornerRadius
    clipsToBounds = true
    labelOriginalCenter = textfield.center

    setupNumberFormatter()

    NotificationCenter.default.addObserver(self, selector: #selector(GMStepper.reset), name: UIApplication.willResignActiveNotification, object: nil)
  }

  func setupNumberFormatter() {
    let decValue = Decimal(stepValue)
    let digits = decValue.significantFractionalDecimalDigits
    formatter.minimumIntegerDigits = 1
    formatter.minimumFractionDigits = showIntegerIfDoubleIsInteger ? 0 : digits
    formatter.maximumFractionDigits = digits
  }

  public override func layoutSubviews() {
    let buttonWidth = bounds.size.width * ((1 - labelWidthWeight) / 2)
    let labelWidth = bounds.size.width * labelWidthWeight

    leftButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: bounds.size.height)
    textfield.frame = CGRect(x: buttonWidth - boxBorderWidth, y: 0, width: labelWidth + 2 * boxBorderWidth, height: bounds.size.height)
    rightButton.frame = CGRect(x: labelWidth + buttonWidth, y: 0, width: buttonWidth, height: bounds.size.height)

    labelMaximumCenterX = textfield.center.x + labelSlideLength + boxBorderWidth
    labelMinimumCenterX = textfield.center.x - labelSlideLength - boxBorderWidth
    labelOriginalCenter = textfield.center
  }

  func updateValue() {
    if stepperState == .shouldIncrease {
      value += stepValue
    } else if stepperState == .shouldDecrease {
      value -= stepValue
    }
  }

  deinit {
    resetTimer()
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: Pan Gesture
extension GMStepper {
  @objc func handlePan(gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
      leftButton.isEnabled = false
      rightButton.isEnabled = false
    case .changed:
      let translation = gesture.translation(in: textfield)
      gesture.setTranslation(CGPoint.zero, in: textfield)

      let slidingRight = gesture.velocity(in: textfield).x > 0
      let slidingLeft = gesture.velocity(in: textfield).x < 0

      // Move the label with pan
      if slidingRight {
        textfield.center.x = min(labelMaximumCenterX, textfield.center.x + translation.x)
      } else if slidingLeft {
        textfield.center.x = max(labelMinimumCenterX, textfield.center.x + translation.x)
      }

      // When the label hits the edges, increase/decrease value and change button backgrounds
      if textfield.center.x == labelMaximumCenterX {
        // If not hit the right edge before, increase the value and start the timer. If already hit the edge, do nothing. Timer will handle it.
        if panState != .hitRightEdge {
          stepperState = .shouldIncrease
          panState = .hitRightEdge
        }

        animateLimitHitIfNeeded()
      } else if textfield.center.x == labelMinimumCenterX {
        if panState != .hitLeftEdge {
          stepperState = .shouldDecrease
          panState = .hitLeftEdge
        }

        animateLimitHitIfNeeded()
      } else {
        panState = .stable
        stepperState = .stable
        resetTimer()

        self.rightButton.backgroundColor = self.buttonsBackgroundColor
        self.leftButton.backgroundColor = self.buttonsBackgroundColor
      }
    case .ended, .cancelled, .failed:
      reset()
    default:
      break
    }
  }

  @objc func reset() {
    panState = .stable
    stepperState = .stable
    resetTimer()

    leftButton.isEnabled = true
    rightButton.isEnabled = true
    textfield.isUserInteractionEnabled = true

    UIView.animate(withDuration: self.labelSlideDuration, animations: {
      self.textfield.center = self.labelOriginalCenter
      self.rightButton.backgroundColor = self.buttonsBackgroundColor
      self.leftButton.backgroundColor = self.buttonsBackgroundColor
    })
  }
}

// MARK: Button Events
extension GMStepper {
  @objc func leftButtonTouchDown(button: UIButton) {
    rightButton.isEnabled = false
    textfield.isUserInteractionEnabled = false
    resetTimer()

    if value == minimumValue {
      animateLimitHitIfNeeded()
    } else {
      stepperState = .shouldDecrease
      animateSlideLeft()
    }

  }

  @objc func rightButtonTouchDown(button: UIButton) {
    leftButton.isEnabled = false
    textfield.isUserInteractionEnabled = false
    resetTimer()

    if value == maximumValue {
      animateLimitHitIfNeeded()
    } else {
      stepperState = .shouldIncrease
      animateSlideRight()
    }
  }

  @objc func typeTextfield(textfield: UITextField) {
    guard let number = Double(textfield.text!) else { return }
    value = number
  }

  @objc func typeTextfieldDidEnd(textfield: UITextField) {
    if textfield.isEmpty {
      value = minimumValue
    }
  }

  @objc func buttonTouchUp(button: UIButton) {
    textfield.resignFirstResponder()
    reset()
  }
}

// MARK: Animations
extension GMStepper {

  func animateSlideLeft() {
    UIView.animate(withDuration: labelSlideDuration) {
      self.textfield.center.x -= self.labelSlideLength
    }
  }

  func animateSlideRight() {
    UIView.animate(withDuration: labelSlideDuration) {
      self.textfield.center.x += self.labelSlideLength
    }
  }

  func animateToOriginalPosition() {
    if self.textfield.center != self.labelOriginalCenter {
      UIView.animate(withDuration: labelSlideDuration) {
        self.textfield.center = self.labelOriginalCenter
      }
    }
  }

  func animateLimitHitIfNeeded() {
    if value == minimumValue {
      animateLimitHitForButton(button: leftButton)
    } else if value == maximumValue {
      animateLimitHitForButton(button: rightButton)
    }
  }

  func animateLimitHitForButton(button: UIButton) {
    UIView.animate(withDuration: limitHitAnimationDuration) {
      button.backgroundColor = self.limitHitAnimationColor
    }
  }
}

// MARK: Timer
extension GMStepper {
  @objc func handleTimerFire(timer: Timer) {
    timerFireCount += 1

    if timerFireCount % timerFireCountModulo == 0 {
      updateValue()
    }
  }

  func scheduleTimer() {
    timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(GMStepper.handleTimerFire), userInfo: nil, repeats: true)
  }

  func resetTimer() {
    if let timer = timer {
      timer.invalidate()
      self.timer = nil
      timerFireCount = 0
    }
  }
}

extension Decimal {
  var significantFractionalDecimalDigits: Int {
    return max(-exponent, 0)
  }
}
