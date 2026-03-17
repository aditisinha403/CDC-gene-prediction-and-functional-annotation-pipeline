FROM perl:5.38-slim

LABEL description="GeneMarkS-2 v1.15 for bacterial gene prediction"
LABEL license="Academic use only - requires license from exon.gatech.edu"

# Copy GeneMarkS-2 binaries and models
COPY biogem compp gmhmmp2 gms2.pl /opt/gms2/
COPY mgm_*.mod /opt/gms2/

# Make binaries executable
RUN chmod +x /opt/gms2/biogem /opt/gms2/compp /opt/gms2/gmhmmp2 /opt/gms2/gms2.pl

# Add to PATH
ENV PATH="/opt/gms2:${PATH}"

WORKDIR /data

ENTRYPOINT ["perl", "/opt/gms2/gms2.pl"]
