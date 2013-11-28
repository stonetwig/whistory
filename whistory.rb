# whistory.rb
require 'rubygems'
require 'sinatra'
require 'imgkit'
require 'stringio'
require 'json'
require 'redis'

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
	name = Digest::MD5.hexdigest("#{params['url']}_#{params['width']}_#{params['height']}")
	@link = redis.get "#{name}"
	unless @link
		begin
			temp_dir = "#{settings.root}/static/img"
			Dir.mkdir(temp_dir) unless Dir.exists?(temp_dir)
			kit   = IMGKit.new(html, quality: 100)
			file = kit.to_file("#{temp_dir}/#{name}.png")
    		@link = "#{name}.png"
		rescue Exception => exception
			@link = "image_not_found.jpg"
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

