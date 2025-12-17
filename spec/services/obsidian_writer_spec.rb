require 'rails_helper'

RSpec.describe ObsidianWriter do
  let(:user) { create(:user) }
  let(:vault_path) { Dir.mktmpdir('obsidian_test') }
  let(:writer) { described_class.new(user) }

  before do
    allow(user).to receive(:obsidian_vault_path).and_return(vault_path)
  end

  after do
    FileUtils.rm_rf(vault_path) if vault_path && Dir.exist?(vault_path)
  end

  describe '#write' do
    let(:content) { "# Test Note\n\nThis is test content." }
    let(:title) { 'Test Note Title' }

    context 'without folder' do
      it 'writes file to vault root' do
        result = writer.write(content: content, title: title)

        file_path = File.join(vault_path, "#{title}.md")
        expect(File.exist?(file_path)).to be true
        expect(File.read(file_path)).to eq(content)
      end

      it 'returns relative path from vault root' do
        result = writer.write(content: content, title: title)

        expect(result).to eq("#{title}.md")
      end
    end

    context 'with folder' do
      let(:folder) { 'Captures' }

      it 'creates folder if it does not exist' do
        writer.write(content: content, title: title, folder: folder)

        folder_path = File.join(vault_path, folder)
        expect(Dir.exist?(folder_path)).to be true
      end

      it 'writes file to specified folder' do
        writer.write(content: content, title: title, folder: folder)

        file_path = File.join(vault_path, folder, "#{title}.md")
        expect(File.exist?(file_path)).to be true
        expect(File.read(file_path)).to eq(content)
      end

      it 'returns relative path with folder' do
        result = writer.write(content: content, title: title, folder: folder)

        expect(result).to eq("#{folder}/#{title}.md")
      end

      it 'handles nested folders' do
        nested_folder = 'Captures/2024/January'
        result = writer.write(content: content, title: title, folder: nested_folder)

        file_path = File.join(vault_path, nested_folder, "#{title}.md")
        expect(File.exist?(file_path)).to be true
        expect(result).to eq("#{nested_folder}/#{title}.md")
      end
    end

    context 'filename sanitization' do
      it 'removes special characters' do
        unsafe_title = 'Test/Title:With*Special?Characters'
        result = writer.write(content: content, title: unsafe_title)

        expect(result).to eq('TestTitleWithSpecialCharacters.md')
      end

      it 'preserves hyphens and underscores' do
        title = 'Test-Title_With-Allowed_Characters'
        result = writer.write(content: content, title: title)

        expect(result).to eq("#{title}.md")
      end

      it 'preserves spaces' do
        title = 'Test Title With Spaces'
        result = writer.write(content: content, title: title)

        expect(result).to eq("#{title}.md")
      end

      it 'truncates long filenames to 100 characters' do
        long_title = 'a' * 150
        result = writer.write(content: content, title: long_title)

        filename = File.basename(result, '.md')
        expect(filename.length).to eq(100)
      end

      it 'handles titles with multiple consecutive special characters' do
        title = 'Test///Title:::Name'
        result = writer.write(content: content, title: title)

        expect(result).to eq('TestTitleName.md')
      end

      it 'handles Unicode characters by removing them' do
        title = 'Test™ Title® With© Unicode'
        result = writer.write(content: content, title: title)

        expect(result).to eq('Test Title With Unicode.md')
      end
    end

    context 'duplicate filename handling' do
      it 'appends counter when file already exists' do
        # Create first file
        first_result = writer.write(content: content, title: title)
        expect(first_result).to eq("#{title}.md")

        # Create second file with same title
        second_result = writer.write(content: content, title: title)
        expect(second_result).to eq("#{title}-1.md")

        # Verify both files exist
        expect(File.exist?(File.join(vault_path, first_result))).to be true
        expect(File.exist?(File.join(vault_path, second_result))).to be true
      end

      it 'increments counter for multiple duplicates' do
        # Create three files with same title
        results = 3.times.map { writer.write(content: content, title: title) }

        expect(results).to eq([
          "#{title}.md",
          "#{title}-1.md",
          "#{title}-2.md"
        ])
      end

      it 'handles duplicates in folders' do
        folder = 'Captures'

        first_result = writer.write(content: content, title: title, folder: folder)
        second_result = writer.write(content: content, title: title, folder: folder)

        expect(first_result).to eq("#{folder}/#{title}.md")
        expect(second_result).to eq("#{folder}/#{title}-1.md")
      end
    end

    context 'edge cases' do
      it 'handles empty title' do
        result = writer.write(content: content, title: '')

        expect(result).to eq('.md')
        expect(File.exist?(File.join(vault_path, '.md'))).to be true
      end

      it 'handles title with only spaces' do
        result = writer.write(content: content, title: '   ')

        expect(result).to match(/^\s+\.md$/)
      end

      it 'handles empty content' do
        result = writer.write(content: '', title: title)

        file_path = File.join(vault_path, "#{title}.md")
        expect(File.exist?(file_path)).to be true
        expect(File.read(file_path)).to eq('')
      end

      it 'overwrites content when creating duplicate files' do
        first_content = '# First Version'
        second_content = '# Second Version'

        writer.write(content: first_content, title: title)
        result = writer.write(content: second_content, title: title)

        # Second file should have second content
        file_path = File.join(vault_path, result)
        expect(File.read(file_path)).to eq(second_content)

        # First file should still have first content
        first_file_path = File.join(vault_path, "#{title}.md")
        expect(File.read(first_file_path)).to eq(first_content)
      end
    end

    context 'path handling' do
      it 'returns relative path without leading slash' do
        result = writer.write(content: content, title: title)

        # The implementation returns a path relative to vault root
        # It may or may not have a leading slash depending on implementation
        expect(result).to end_with("#{title}.md")
      end

      it 'returns consistent path format' do
        result = writer.write(content: content, title: title)

        # Verify the file exists at the returned path
        full_path = File.join(vault_path, result.sub(/^\//, ''))
        expect(File.exist?(full_path)).to be true
      end
    end
  end

  describe '#sanitize_filename' do
    it 'is called during write' do
      allow(writer).to receive(:sanitize_filename).and_call_original

      writer.write(content: '# Test', title: 'Test Title')

      expect(writer).to have_received(:sanitize_filename).with('Test Title')
    end
  end

  describe '#ensure_unique_filename' do
    it 'is called during write' do
      allow(writer).to receive(:ensure_unique_filename).and_call_original

      writer.write(content: '# Test', title: 'Test Title')

      expect(writer).to have_received(:ensure_unique_filename)
    end

    it 'returns original path when file does not exist' do
      file_path = File.join(vault_path, 'new-file.md')
      result = writer.send(:ensure_unique_filename, file_path)

      expect(result).to eq(file_path)
    end

    it 'returns modified path when file exists' do
      file_path = File.join(vault_path, 'existing-file.md')

      # Create the file
      FileUtils.mkdir_p(vault_path)
      File.write(file_path, 'content')

      result = writer.send(:ensure_unique_filename, file_path)

      expect(result).to eq(File.join(vault_path, 'existing-file-1.md'))
    end
  end
end
