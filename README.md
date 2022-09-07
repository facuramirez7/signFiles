# signFiles
Script to sign any PDF


First, install pdftk and wkhtmltopdf (Debian 10)
```bash
sudo apt install pdftk
sudo apt update
sudo apt -y install wget
```



You must pass the document to be signed as an argument, then the PDF where the signature will be placed, 3 the destination of the signed file and finally the number of sheets to sign

For example

```bash
./firma_documento.sh doc.pdf sign.pdf dest.pdf 4-5
```
