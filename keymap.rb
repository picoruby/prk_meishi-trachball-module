require "consumer_key"
require "adns5050"

kbd = Keyboard.new

kbd.init_direct_pins([21, 23, 20])

kbd.add_layer :default, %i[KC_BTN1 BTN3_RAISE KC_BTN2]
kbd.add_layer :raise,   %i[KC_VOLD BTN3_RAISE KC_VOLU]

kbd.define_mode_key :BTN3_RAISE, [ :KC_BTN3, :raise, 150, 150 ]

adns5050 = ADNS5050.new(unit: :BITBANG, sck_pin: 26, copi_pin: 27, cipo_pin: 27, cs_pin: 22)
adns5050.reset_chip
adns5050.set_cpi(1250)
kbd.append adns5050.mouse

encoder = RotaryEncoder.new(0, 1)
encoder.clockwise do
  # scroll up
  USB.merge_mouse_report(0, 0, 0, 0, -1)
end
encoder.counterclockwise do
  # scroll down
  USB.merge_mouse_report(0, 0, 0, 0, 1)
end
kbd.append encoder

kbd.start!

