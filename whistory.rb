# whistory.rb
require 'sinatra'
require 'imgkit'
require 'stringio'
require 'json'
require 'redis'

set :static, true
set :public_folder, File.dirname(__FILE__) + '/public'

IMGKit.configure do |config| config.wkhtmltoimage = '/usr/local/bin/wkhtmltoimage' end
redis = Redis.new  


helpers do  
  include Rack::Utils  
  alias_method :h, :escape_html
end  

get '/' do
  erb :index
end

post '/' do
	@errors = validate(params)
	if @errors.empty?
		html = "http://#{params['url']}"
		name = Digest::MD5.hexdigest("#{params['url']}_#{params['width']}_#{params['height']}")
		@link = redis.get "#{name}"
		unless @link
			begin
				temp_dir = "#{settings.root}/tmp"
				Dir.mkdir(temp_dir) unless Dir.exists?(temp_dir)
				kit   = IMGKit.new(html, quality: 100, width: 1280, height: 720)
				temp_file = "#{temp_dir}/#{name}.png"
				img = Image.from_blob(kit.to_img(:png)).first
				thumb = img.resize_to_fill(params['width'].to_i, params['height'].to_i)
        		thumb.write temp_file
        		@link = "https://localhost:9393/tmp/#{name}.png"
			rescue Exception => exception
				@link = "image_not_found.jpg"
			end
		end
	else
		@link = "image_not_found.jpg"
	end
	erb :index
end


def validate(params)
	errors = {}	

	unless params['url'] && given?(params['url'])
		errors['url']   = "This field is required"
	end

	unless params['width'] && given?(params['width'])
		errors['width']   = "This field is required"
	end

	unless params['height'] && given?(params['height'])
		errors['height']   = "This field is required"
	end

	unless params['format'] && given?(params['format'])
		errors['format']   = "This field is required"
	end

	errors
end

def given?(field)
	!field.empty?
end

