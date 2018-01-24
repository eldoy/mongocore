require 'zlib'

test 'Binary'

m = Model.new
zip = Zlib::Deflate.deflate('hello')

m.zip_file = zip

is m.zip_file, :a? => BSON::Binary

is m.save

m.reload

is m.zip_file, :a? => BSON::Binary

val = Zlib::Inflate.inflate(m.zip_file.data)

is val, 'hello'
