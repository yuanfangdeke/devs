module DEVS
  # The major version number
  MAJOR = 0
  # The minor version number
  MINOR = 5
  # The patch version number
  PATCH = 0
  # The build version number
  BUILD = nil

  VERSION = [MAJOR, MINOR, PATCH, BUILD].compact.join('.').freeze
end
