require 'csv'

desc "Load database from CSV -- invoke with rake load_csv[file_name.csv]"
task :load_csv, [:csv_file] => [:environment, :build_db] do |t, args|
  puts "Loading #{args[:csv_file]} ... "
  count = 0

  ActiveRecord::Base.transaction do
    CSV.foreach(args[:csv_file], headers: true, encoding: "iso-8859-1:utf-8", header_converters: :symbol) do |row|
  		count += 1
    
      row = LoadCsvHelper.convert(row.to_hash) 		
  		Institution.create(row)

  		print "\r Records: #{count}" 
    end
  end

	puts "\nDone ... Woop Woop!"
end

task build_db: :environment do
  # TODO: Back up DB prior to drop
  
	puts "Clearing logs ..."
	Rake::Task['log:clear'].invoke

	puts "Dropping database ..."
	Rake::Task['db:drop'].invoke

	puts "Creating database ..."
	Rake::Task['db:create'].invoke

	puts "Running migrations ..."
	Rake::Task['db:migrate'].invoke

	puts "Seeding database ..."
	Rake::Task['db:seed'].invoke

	puts "Done!\n\n\n"
end

###############################################################################
## LoadCsvHelper
###############################################################################
class LoadCsvHelper
  TRUTHY = %w(yes true t 1)
  COLUMNS_NOT_IN_CSV = %w(id institution_type_id created_at updated_at)

  CONVERSIONS = { 
    string: :to_str, float: :to_float, integer: :to_int, boolean: :to_bool 
  }

  #############################################################################
  ## get_columns
  ## Gets Institution column names, returning only those columns that are in
  ## the CSV data file.
  #############################################################################
  def self.get_columns
    columns = Institution.column_names || []
    COLUMNS_NOT_IN_CSV.each { |col_name| columns.delete(col_name) }

    columns
  end

  #############################################################################
  ## convert(row)
  ## Converts the columns in the csv row to an appropriate data type for the 
  ## Institution and InstitutionType models.
  #############################################################################
  def self.convert(row)
    # For each column name in the CSV, get the column's data type and convert
    # the row to the appropriate type.
    cnv_row = {};

    get_columns.each do |name|
      col_type = Institution.columns_hash[name].type

      if conversion = CONVERSIONS[col_type]
        cnv = LoadCsvHelper.send(conversion, row[name.to_sym])

        if col_type == :integer || col_type == :float
          cnv_row[name.to_sym] = cnv if cnv.present?
        else
          cnv_row[name.to_sym] = cnv
        end
      end
    end

    cnv_row[:institution_type_id] = to_institution_type(row)
    cnv_row[:zip] = pad_zip(row)

    cnv_row
  end

  #############################################################################
  ## to_institution_type(row)
  ## Converts CSV type data to an associated type in the database. Also
  ## removes fields in the CSV that have become redundant.
  #############################################################################
  def self.to_institution_type(row)
    id = InstitutionType.find_or_create_by(name: row[:type]).try(:id)
    [:type, :correspondence, :flight].each { |key| row.delete(key) }

    id
  end

  #############################################################################
  ## pad_zip
  ## Pads the CSV zip code to 5 characters if necessary.
  #############################################################################
  def self.pad_zip(row)
    row[:zip].try(:rjust, 5, '0')
  end

  #############################################################################
  ## to_bool(value)
  ## Converts the string value to a boolean.
  #############################################################################
	def self.to_bool(value)
    TRUTHY.include?(value.try(:downcase))
	end

  #############################################################################
  ## to_int(value)
  ## Converts the string value to a integer. Removes numeric formatting
  ## characters.
  #############################################################################
  def self.to_int(value)
    value.try(:gsub, /[\$,]|null/i, '')
  end

  #############################################################################
  ## to_float(value)
  ## Converts the string value to a float. Removes numeric formatting
  ## characters.
  #############################################################################
  def self.to_float(value)
    value.try(:gsub, /[\$,]|null/i, '')
  end

  #############################################################################
  ## to_str(value)
  ## Removes single and double quotes from strings.
  #############################################################################
  def self.to_str(value)
    value = value.to_s.gsub(/["']/, '').truncate(255)

    if value.present?
      value = value.split.map(&:capitalize).join(' ') 
    end

    value
  end
end