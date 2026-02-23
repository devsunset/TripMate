/**
 * FCM 토큰 컨트롤러
 * 푸시 알림용 FCM 토큰 등록·삭제.
 */
const FcmToken = require('../models/fcmToken');
const User = require('../models/user');
const { LIMITS, checkMaxLength } = require('../utils/fieldLimits');

/** FCM 토큰 등록(있으면 deviceType 갱신) */
exports.registerFcmToken = async (req, res, next) => {
  try {
    const { token, deviceType } = req.body;
    const firebaseUid = req.user.uid;
    if (!token) {
      return res.status(400).json({ message: 'FCM 토큰이 필요합니다.' });
    }
    let err = checkMaxLength(token, LIMITS.fcmToken, 'FCM 토큰');
    if (err) return res.status(400).json({ message: err });
    if (deviceType != null) {
      err = checkMaxLength(deviceType, LIMITS.deviceType, '기기 유형');
      if (err) return res.status(400).json({ message: err });
    }
    const user = await User.findOne({ where: { firebase_uid: firebaseUid } });
    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }
    const [fcmToken, created] = await FcmToken.findOrCreate({
      where: { userId: user.email, token: token },
      defaults: { deviceType: deviceType },
    });
    if (!created) {
      fcmToken.deviceType = deviceType;
      await fcmToken.save();
    }
    res.status(200).json({ message: 'FCM 토큰이 등록되었습니다.', fcmToken });
  } catch (error) {
    console.error('registerFcmToken 오류:', error);
    next(error);
  }
};

/** FCM 토큰 삭제 */
exports.deleteFcmToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    const firebaseUid = req.user.uid;
    if (!token) {
      return res.status(400).json({ message: 'FCM 토큰이 필요합니다.' });
    }
    const user = await User.findOne({ where: { firebase_uid: firebaseUid } });
    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }
    const deletedRows = await FcmToken.destroy({ where: { userId: user.email, token: token } });
    if (deletedRows === 0) {
      return res.status(404).json({ message: '해당 사용자의 FCM 토큰을 찾을 수 없습니다.' });
    }
    res.status(204).send();
  } catch (error) {
    console.error('deleteFcmToken 오류:', error);
    next(error);
  }
};
