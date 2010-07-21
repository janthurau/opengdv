require 'gdv/format/rectype'
require 'gdv/format/recindex'
require 'gdv/format/reader'

module GDV::Format
    def self.load_rectypes(file)
        fields = []
        parts = []
        @rectypes = []
        map = {}
        @maps = {}
        cnt = 0
        begin
            file.each_line do |line|
                cnt += 1
                line.chomp!
                a = line.split(/:/)
                typ = a.first
                case typ
                when "K":
                    @rectypes << RecType::parse(parts, a)
                    parts = []
                when "T":
                    parts << Part::parse(fields, a)
                    fields = []
                when "F":
                    fields << Field::parse(a, @maps)
                # Types with fixed values
                when "V":
                    map[a[1]] = a[2]
                when "M":
                    t = a[1].to_sym
                    if @maps[t]
                        raise FormatError, "Duplicate value map #{t}"
                    end
                    @maps[t] = ValueMap.new(a[2], map)
                    map = {}
                end
            end
        rescue FormatError => e
            puts "#{cnt}:#{e}"
            raise e
        end
        @rectypes.each { |rt| rt.finalize }
    end

    class << self
        attr_reader :rectypes, :maps, :recindex
    end

    def self.classify(record)
        @recindex.classify(record)
    end

    def self.init
        if @rectypes.nil?
            File.open(File.join(GDV::format_path, 'rectypes.txt')) do |f|
                load_rectypes(f)
            end
        end
        # Build the index for classifying records
        if @recindex.nil?
            parts = @rectypes.inject([]) { |l, rt| l + rt.parts }
            p = parts.shift
            @recindex = RecIndex.new(nil, p[:sid], p)
            parts.each do |p|
                GDV::log "\n\n** Tree:\n#{@recindex.print}\n"
                @recindex.insert(p)
            end
        end
    end

    # Constants for the different kinds of 'satz'
    VORSATZ      = "0001"
    NACHSATZ     = "9999"
    ADDRESS_TEIL = "0100"
    SIGNATURES   = "0352"
    CLAUSES      = "0350"
    REBATES      = "0390"
    GENERAL_CONTRACT = "0200"
end
