# frozen_string_literal: true

require "net/http"
require "uri"
require "fileutils"

# Downloads MOE Taigi dictionary open data files.
module MoeFetcher
  BASE_URL = "https://sutian.moe.edu.tw/media/senn"

  FILES = {
    dictionary: "ods/kautian.ods",
    audio_entries_mp3: "sutiau-mp3.zip",
    audio_examples_mp3: "leku-mp3.zip"
  }.freeze

  module_function

  # Download a specific resource. Returns the local file path.
  def fetch(key, dest_dir: "data")
    path = FILES.fetch(key)
    url = "#{BASE_URL}/#{path}"
    filename = File.basename(path)
    dest_path = File.join(dest_dir, filename)

    FileUtils.mkdir_p(dest_dir)

    if File.exist?(dest_path)
      puts "  Already exists: #{dest_path}"
      return dest_path
    end

    puts "  Downloading #{url}..."
    download(url, dest_path)
    puts "  Saved to #{dest_path} (#{format_size(File.size(dest_path))})"
    dest_path
  end

  # Download all resources.
  def fetch_all(dest_dir: "data")
    FILES.each_key { |key| fetch(key, dest_dir: dest_dir) }
  end

  def download(url, dest_path, redirect_limit: 5)
    raise "Too many redirects" if redirect_limit == 0

    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess
          total = response["content-length"]&.to_i
          downloaded = 0
          last_report = 0
          File.open(dest_path, "wb") do |f|
            response.read_body do |chunk|
              f.write(chunk)
              downloaded += chunk.size
              if total && total > 0
                pct = (downloaded * 100) / total
                if pct >= last_report + 10
                  last_report = pct / 10 * 10
                  $stdout.print "  #{format_size(downloaded)} / #{format_size(total)} (#{pct}%)\n"
                  $stdout.flush
                end
              end
            end
          end
        when Net::HTTPRedirection
          download(response["location"], dest_path, redirect_limit: redirect_limit - 1)
        else
          raise "Download failed: #{response.code} #{response.message}"
        end
      end
    end
  end

  def format_size(bytes)
    if bytes >= 1024 * 1024
      format("%.1f MB", bytes.to_f / (1024 * 1024))
    elsif bytes >= 1024
      format("%.1f KB", bytes.to_f / 1024)
    else
      "#{bytes} B"
    end
  end
end
