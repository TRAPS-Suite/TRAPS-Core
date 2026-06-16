import csv

new_files = []

with open('/work/crosslab/hsommer/TRAPS/workflow/one_ref.csv', mode='r', newline='', encoding='utf-8') as file:
    reader = csv.reader(file)
    
    # Optional: Skip the header row if you do not want to print it
    header = next(reader) 
    
    for row in reader:
        print(row) 

        with open(row[1], "r") as infile:
            first_line = infile.readline()
            first_line = first_line.replace("\n", "")

            first_line_new = first_line + ", " + row[0]
            print(first_line_new)
        with open(row[1], 'r', encoding='utf-8') as infile:
            lines = infile.readlines()
        lines[0] = first_line_new + "\n"



        dir_split = row[1].split("/")

        new_file = dir_split[len(dir_split)-1]
        new_file = new_file.replace(".fasta", "")
        new_file = new_file + "_new.fasta"

        new_file = "/work/crosslab/hsommer/pipeline_runs/ill_run/" + new_file

        with open(new_file, 'w', encoding='utf-8') as file:
            file.writelines(lines)
        new_files.append(new_file)

with open("/work/crosslab/hsommer/pipeline_runs/ill_run/" + "master.fasta" , 'w', encoding='utf-8') as master_fasta:
    for file in new_files:
        with open(file, 'r', encoding='utf-8') as infile:
            lines = infile.readlines()
            master_fasta.writelines(lines)


