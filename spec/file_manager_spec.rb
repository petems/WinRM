describe WinRM::FileManager, :integration => true do
  let(:service) { winrm_connection }
  let(:dest_dir) { File.join(subject.temp_dir, 'winrm_filemanager_test') }

  subject { WinRM::FileManager.new(service) }

  context 'exists?' do
    it 'should exist' do
      expect(subject.exists?('c:/windows')).to be true
      expect(subject.exists?('c:/foobar')).to be false
    end
  end

  context 'create and delete dir' do
    it 'should create the directory recursively' do
      subdir = File.join(dest_dir, 'subdir1', 'subdir2')
      expect(subject.create_dir(subdir)).to be true
      expect(subject.exists?(subdir)).to be true
      expect(subject.create_dir(subdir)).to be true
      expect(subject.delete(subdir)).to be true
      expect(subject.exists?(subdir)).to be false
    end
  end

  context 'temp_dir' do
    it 'should return the remote users temp dir' do
      expect(subject.temp_dir).to match(/C:\/Users\/\w+\/AppData\/Local\/Temp/)
    end
  end

  context 'upload file' do
    let(:src_file) { __FILE__ }
    let(:dest_file) { File.join(dest_dir, File.basename(src_file)) }

    before(:each) do
      expect(subject.delete(dest_dir)).to be true
    end

    it 'should upload the file to the specified file' do
      subject.upload(src_file, dest_file)
      expect(subject.exists?(dest_file)).to be true
    end

    it 'should upload the file to the specified directory' do
      subject.upload(src_file, dest_dir)
      expect(subject.exists?(dest_file)).to be true
    end

    it 'should upload the file to the specified nested directory' do
      dest_sub_dir = File.join(dest_dir, 'subdir')
      dest_sub_dir_file = File.join(dest_sub_dir, File.basename(src_file))
      subject.upload(src_file, dest_sub_dir)
      expect(subject.exists?(dest_sub_dir_file)).to be true
    end

    it 'yields progress data' do
      total = subject.upload(src_file, dest_file) do |bytes_copied, total_bytes, local_path, remote_path|
        expect(total_bytes).to be > 0
        expect(bytes_copied).to eq(total_bytes)
        expect(local_path).to eq(src_file)
        expect(remote_path).to eq(dest_file)
      end
      expect(total).to be > 0
    end

    it 'copies the exact file content' do
      downloaded_file = File.join(Dir.tmpdir, 'downloaded')
      subject.upload(src_file, dest_file)
      subject.download(dest_file, downloaded_file)
      expect(File.read(downloaded_file).chomp).to eq(File.read(src_file).chomp)
    end

    it 'should not upload the file when content matches' do
      subject.upload(src_file, dest_dir)
      bytes_uploaded = subject.upload(src_file, dest_dir)
      expect(bytes_uploaded).to eq 0
    end

    it 'should upload file when content differs' do
      another_src_file = File.join(File.expand_path(File.dirname(__FILE__)), 'matchers.rb')
      subject.upload(another_src_file, dest_file)
      expect(subject.exists?(dest_file)).to be true
      bytes_uploaded = subject.upload(src_file, dest_file)
      expect(bytes_uploaded).to be > 0
    end
  end
end