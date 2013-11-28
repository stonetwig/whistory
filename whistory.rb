# whistory.rb
require 'rubygems'
require 'chunky_png'
require 'sinatra'
require 'imgkit'
require 'stringio'
require 'json'
require 'redis'

include ChunkyPNG::Color

set :static, true
set :public_folder, File.dirname(__FILE__) + '/static'

IMGKit.configure do |config|
	config.wkhtmltoimage = '/usr/local/bin/wkhtmltoimage' 
	config.default_format = :png
end
redis = Redis.new  


helpers do  
  include Rack::Utils  
  alias_method :h, :escape_html
end  

get '/' do
  erb :index
end

post '/' do
	html = "#{params['url']}"
	html2 = "#{params['url2']}"
	name = Digest::MD5.hexdigest("#{params['url']}_#{params['width']}_#{params['height']}")
	name2 = Digest::MD5.hexdigest("#{params['url2']}_#{params['width']}_#{params['height']}")

	@links = redis.get "#{name}"
	unless @links
		begin
			@links = []
			temp_dir = "#{settings.root}/static/img"
			Dir.mkdir(temp_dir) unless Dir.exists?(temp_dir)

			# Site 1
			kit   = IMGKit.new(html, quality: 100)
			file = kit.to_file("#{temp_dir}/#{name}.png")
    		@links.push("#{name}.png")

    		# Site 2
    		kit   = IMGKit.new(html2, quality: 100)
			file2 = kit.to_file("#{temp_dir}/#{name2}.png")
    		@links.push("#{name2}.png")

    		#calculate diff
    		images = [
				ChunkyPNG::Image.from_file(file),
				ChunkyPNG::Image.from_file(file2)
			]
			 
			images.first.height.times do |y|
				images.first.row(y).each_with_index do |pixel, x|
				 
				images.last[x,y] = rgb(
					r(pixel) + r(images.last[x,y]) - 2 * [r(pixel), r(images.last[x,y])].min,
					g(pixel) + g(images.last[x,y]) - 2 * [g(pixel), g(images.last[x,y])].min,
					b(pixel) + b(images.last[x,y]) - 2 * [b(pixel), b(images.last[x,y])].min
				)
				end
			end
			@diff = "#{temp_dir}/diff.png";
			images.last.save(@diff)

		rescue Exception => exception
			@links.push("image_not_found.jpg")
			puts exception
		end
	end
	erb :index
end


def validate(params)
	errors = {}	

	errors
end

def given?(field)
	!field.empty?
end

