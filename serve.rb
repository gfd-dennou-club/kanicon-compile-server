require "sinatra"
require "fileutils"
require "shellwords"

# JavaScriptやアセットを配信するドキュメントルートです。
set :public_folder, File.join(__dir__, "public")

# [GET] /upload_file
#
# Rubyコードをアップロードする画面です。
# フォームは/uploadにPOSTされます。
#
# - (PHP) refs https://github.com/gfd-dennou-club/kanicon-compile-server/blob/b3e8653eaf858247c98824dc0bd1006565ab9f7d/upload_file.php
get "/upload_file" do
  erb :upload_file
end

# [POST] /upload
#
# Rubyコードのコンパイル結果画面です。
# マイコンへの書き込みまたは提出を行います。
# 提出の場合、フォームは/submitにPOSTされます。
#
# - (PHP) refs https://github.com/gfd-dennou-club/kanicon-compile-server/blob/b3e8653eaf858247c98824dc0bd1006565ab9f7d/upload.php
post "/upload" do
  @error_messages = []

  # POSTで受け取ったソースコードを変数に保存
  master_code = presence(params["master_code"])
  @master_code = master_code
  slave_code = presence(params["slave_code"])
  @slave_code = slave_code

  # 一意なファイル名のための識別子
  prefix = [
    # タイムスタンプを生成
    Time.now.strftime("%Y%m%d-%H%M%S"),
    # 3文字のランダム文字列を生成
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPUQRSTUVWXYZ".chars.sample(3).join
  ].join

  # ファイル保存先のディレクトリ
  source_dirname = File.join(__dir__, "source")
  master_fname = File.join(source_dirname, "#{prefix}_master.rb")
  slave_fname = File.join(source_dirname, "#{prefix}_slave.rb")

  # ソースコードをRubyファイルとして保存
  begin
    FileUtils.mkdir_p(source_dirname)
    FileUtils.chmod("g+w", source_dirname)

    if master_code
      File.write(master_fname, master_code)
      FileUtils.chmod("g+w", master_fname)
    end

    if slave_code
      File.write(slave_fname, slave_code)
      FileUtils.chmod("g+w", slave_fname)
    end
  rescue => e
    @error_messages << "failed to save code."
    puts e.full_message
    halt(erb :upload)
  end

  # 1つのフォルダの下にmasterとslaveを.mrbcとして配置
  compiled_dirname = File.join(__dir__, "compiled")
  mrbc_dirname = File.join(compiled_dirname, prefix)

  begin
    FileUtils.mkdir_p(mrbc_dirname)
    FileUtils.chmod("g+w", mrbc_dirname)
  rescue => e
    @error_messages << ""
    puts e.full_message
    halt(erb :upload)
  end

  # master program
  master_mrbc_fname = File.join(mrbc_dirname, "master.mrbc")
  if master_code
    cmd = ["mrbc", "-o", master_mrbc_fname, "-E", master_fname].shelljoin
    `#{cmd}`
  else
    # use an empty file.
    FileUtils.cp(File.join(compiled_dirname, "master.mrbc"), master_mrbc_fname)
  end

  # slave program
  slave_mrbc_fname = File.join(mrbc_dirname, "slave.mrbc")
  if slave_code
    cmd = ["mrbc", "-o", slave_mrbc_fname, "-E", slave_fname].shelljoin
    `#{cmd}`
  else
    # use an empty file.
    FileUtils.cp(File.join(compiled_dirname, "slave.mrbc"), slave_mrbc_fname)
  end

  # authority
  Dir[File.join(mrbc_dirname, "*")].each do |mrbc_fname|
    FileUtils.chmod("g+w", mrbc_fname)
  end

  binfilename = File.join(__dir__, "bin", "mrbc.#{prefix}.bin")

  # バイナリファイル生成
  cmd = ["mkspiffs", "-c", mrbc_dirname, "-p", "256", "-b", "4096", "-s", "0xF000", binfilename].shelljoin
  `#{cmd}`
  FileUtils.chmod("g+w", binfilename)
  @is_compiled = true

  # [TODO] 削除 (PHPでは必要)
  # # わからないが、以下2行消すと動作しない
  # bin_file = File.open(binfilename, "rb")
  # bin_file.close

  begin
    @data = File.binread(binfilename)
  rescue => e
    @error_messages << "failed to read binary file"
    puts e.full_message
  end

  erb :upload
end

# [POST] /submit
#
# Rubyコード提出後の画面です。
# - (PHP) refs https://github.com/gfd-dennou-club/kanicon-compile-server/blob/b3e8653eaf858247c98824dc0bd1006565ab9f7d/submit.php
post "/submit" do
  @error_messages = []

  # POSTで受け取ったソースコードを変数に保存
  master_code = presence(params["master_code"])
  slave_code = presence(params["slave_code"])
  team = presence(params["team"])

  # チーム名フォルダ以下にmaster/slaveをそれぞれ保存
  team_dirname = File.join(__dir__, "submit", team)
  master_fname = File.join(team_dirname, "master.rb")
  slave_fname = File.join(team_dirname, "slave.rb")

  # ソースコードをRubyファイルとして保存
  begin
    FileUtils.mkdir_p(team_dirname)
    FileUtils.chmod("g+w", team_dirname)

    if master_code
      File.write(master_fname, master_code)
      FileUtils.chmod("g+w", master_fname)
    end

    if slave_code
      File.write(slave_fname, slave_code)
      FileUtils.chmod("g+w", slave_fname)
    end
  rescue => e
    @error_messages << "failed to save code."
    puts e.full_message
  end

  halt(erb :submit)
end

# nilまたは空（empty）の場合はnilを返します。そうでない場合は引数そのものを返します。
#
# @example
#   presence(nil) # => nil
#   presence("")  # => nil
#   presence("a") # => "a"
def presence(value)
  if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    nil
  end
  value
end
