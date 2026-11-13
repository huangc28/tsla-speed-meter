import numpy as np
from PIL import Image
exec(open('fcmp.py').read().split("rows=[]; seen={}")[0])
img=np.asarray(Image.open('sf-86.png').convert('L'))
for i,w in enumerate(["SF Pro 450 ss01","SF Pro 500 ss01","SF Pro 550 ss01","SF Rounded 450 ss01","SF Rounded 500 ss01","SF Rounded 550 ss01","SF Pro 500 ss01+ss02","SF Pro 500 plain"]):
    cell=img[i*400:(i+1)*400]>127; d,segs=digits(cell)
    i8=cmp(rd[0],d[0]); i6=cmp(rd[1],d[1]); s8=stem(d[0])
    print(w,'avg %.3f | 8 IoU %.3f 6 IoU %.3f | 8 w/h %.3f stem %.3f horiz %.3f | 6 w/h %.3f | gap/h %.3f | capH/em %.4f'%((i8+i6)/2,i8,i6,d[0].shape[1]/d[0].shape[0],*s8,d[1].shape[1]/d[1].shape[0],(segs[1][0]-segs[0][1])/d[0].shape[0],d[0].shape[0]/300))
Image.fromarray(img[400:800]).resize((700,200)).save('sf-ss01.png')
