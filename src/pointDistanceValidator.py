from math import sqrt

# -- measured values --
# 1 cm = 138px
PIXELS_PER_CM = 138


# -- parameters default --
# startByteIndex: 152
# distanceMaxCm: 15
def validateDistances(camOutput, startByteIndex:int, distanceMaxCm: int) -> bool:
    posStartIndex = startByteIndex
    posValX=-1
    posValY=-1

    foundPoints = []

    while posValX != 0 and posValY != 0:
        cvArrX = camOutput[posStartIndex:(posStartIndex + 4)]
        rArrX = reversed(cvArrX)
        posValX = int.from_bytes(rArrX,byteorder="big") / 1000

        posStartIndex = posStartIndex + 4

        cvArrY = camOutput[posStartIndex:(posStartIndex + 4)]
        rArrY = reversed(cvArrY)
        posValY = int.from_bytes(rArrY,byteorder="big") / 1000
        
        posStartIndex = posStartIndex + 4

        if posValY > 0 and posValX > 0:
            # print('X: ' + str(posValX) + ', Y:' + str(posValY))
            foundPoints.append({'X': posValX, 'Y': posValY })

    faultDistPoints = []

    if len(foundPoints) > 0:
        for fp in foundPoints:
            for matchFp in foundPoints:
                # print(abs(sqrt((matchFp['X'] - fp['X'])**2 + (matchFp['Y'] - fp['Y'])**2)))
                if matchFp != fp and abs(sqrt((matchFp['X'] - fp['X'])**2 + (matchFp['Y'] - fp['Y'])**2)) <= (PIXELS_PER_CM * distanceMaxCm):
                    faultDistPoints.append({'P1': fp, 'P2': matchFp, 'DIST': abs(sqrt((matchFp['X'] - fp['X'])**2 + (matchFp['Y'] - fp['Y'])**2))})
                    break

    return len(faultDistPoints) == 0

