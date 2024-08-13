class VideosController < ApplicationController
  def create
    @video = Video.new(video_params)
    if @video.save
      render json: { message: 'Video uploaded successfully' }, status: :created
    else
      render json: { errors: @video.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    video = Video.find(params[:id])
    if video.file.attached?
      hls_path = convert_to_hls(video.file)
      if hls_path
        send_file hls_path, type: 'application/x-mpegURL', disposition: 'inline'
      else
        render json: { error: 'Error converting video to HLS' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Video not found' }, status: :not_found
    end
  end

  private

  def video_params
    params.require(:video).permit(:file)
  end

  def convert_to_hls(file)
    input_path = ActiveStorage::Blob.service.send(:path_for, file.key)
    output_dir = Rails.root.join('public', 'videos')
    output_path = output_dir.join("#{file.key}.m3u8")

    # Ensure the output directory exists
    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

    # Use ffmpeg to convert the video to HLS format
    system("ffmpeg -i #{input_path} -codec: copy -start_number 0 -hls_time 10 -hls_list_size 0 -f hls #{output_path}")

    output_path if File.exist?(output_path)
  end
end