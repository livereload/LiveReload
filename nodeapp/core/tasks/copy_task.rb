
class CopyTask

    include Rake::DSL

    def initialize task_name, src_file, dst_files
        dst_files.each do |dst_file|
            file dst_file => src_file do
                mkdir_p File.dirname(dst_file)
                cp src_file, dst_file
            end

            task task_name => [dst_file]
        end

        desc "Copy #{src_file} into #{dst_files.length} destination(s)"
        task task_name
    end

end
