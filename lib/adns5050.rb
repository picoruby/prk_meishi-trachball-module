# Library for ADNS-5050 optical sensor
# filepath: /lib/adns5050.rb
require "mouse"
require "spi"

class ADNS5050
  CPI = [ nil, 125, 250, 375, 500, 625, 750, 875, 1000, 1125, 1250, 1375 ]
  DEFAULT_CPI = 1250

  def initialize(unit:, sck_pin:, copi_pin:, cipo_pin:, cs_pin:)
    @spi = SPI.new(unit: unit, sck_pin: sck_pin, copi_pin: copi_pin, cipo_pin: cipo_pin, cs_pin: cs_pin)
    @mouse = Mouse.new(driver: @spi)
    @mouse.task do |mouse, keyboard|
      y, x = mouse.driver.select do |spi|
        spi.write(0x63) # Motion_Burst
        spi.read(2).bytes
      end
      next unless x && y
      if 0 < x || 0 < y
        x = 0x7F < x ? (~x & 0xff) + 1 : -x
        y = 0x7F < y ? (~y & 0xff) + 1 : -y
        # Rotate by 45 degrees && adjust sensitivity
        x, y = (x - y) * 7 / 50, (x + y) * 7 / 50
        if keyboard.layer != :default
          x = 0 < x ? 1 : (x < 0 ? -1 : x)
          y = 0 < y ? 1 : (y < 0 ? -1 : y)
          USB.merge_mouse_report(0, 0, 0, y, -x)
        else
          USB.merge_mouse_report(0, y, x, 0, 0)
        end
      end
    end
  end

  attr_reader :mouse

  def get_cpi
    @spi.select do |spi|
      spi.write(0x19)
      spi.read(1).bytes[0] & 0b1111
    end
  end

  def set_cpi(cpi)
    index = CPI.index(cpi) || DEFAULT_CPI
    @spi.select do |spi|
      spi.write(0x19 | 0x80, index | 0b10000)
    end
    puts "CPI: #{CPI[index]}"
  end

  def reset_chip
    @spi.select do |spi|
      spi.write(0x3a | 0x80, 0x5a)
    end
    sleep_ms 10
    puts "ADNS-5050 power UP"
  end

end
