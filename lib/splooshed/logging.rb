module Logging
  def log_info(string)
    log(string, " [INFO]")
  end

  def log_error(string)
    log(string, "[ERROR]")
  end

  def log_and_throw_error(string)
    log_error string
    throw string
  end

  private

  def log(string, type)
    class_name = (self.superclass && self.name) rescue self.class.name  # works for both classes and objects
    puts "[#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}] #{type}  #{class_name}> #{string}"
  end
end