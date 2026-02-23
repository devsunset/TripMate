/**
 * 일정 컨트롤러
 * 일정 목록/단건 조회, 생성, 수정, 삭제. 작성자만 수정/삭제 가능. 일차·활동은 중첩 생성/갱신.
 */
const { Op } = require('sequelize');
const Itinerary = require('../models/itinerary');
const ItineraryDay = require('../models/itineraryDay');
const ItineraryActivity = require('../models/itineraryActivity');
const User = require('../models/user');
const { LIMITS, checkMaxLength } = require('../utils/fieldLimits');

/** 일정 목록: 쿼리 search, limit, offset */
exports.getAllItineraries = async (req, res, next) => {
  try {
    const { search, limit = 10, offset = 0 } = req.query;
    const whereConditions = {};

    if (search) {
      whereConditions[Op.or] = [
        { title: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
      ];
    }

    const itineraries = await Itinerary.findAndCountAll({
      where: whereConditions,
      include: [
        { model: User, as: 'Author', attributes: ['firebase_uid', 'email'] },
        {
          model: ItineraryDay,
          as: 'Days',
          include: [
            { model: ItineraryActivity, as: 'Activities' },
          ],
        },
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']],
    });

    res.status(200).json({
      total: itineraries.count,
      limit: parseInt(limit),
      offset: parseInt(offset),
      itineraries: itineraries.rows,
    });
  } catch (error) {
    console.error('getAllItineraries 오류:', error);
    next(error);
  }
};

exports.getItineraryById = async (req, res, next) => {
  try {
    const { itineraryId } = req.params;

    const itinerary = await Itinerary.findByPk(itineraryId, {
      include: [
        { model: User, as: 'Author', attributes: ['firebase_uid', 'email'] },
        {
          model: ItineraryDay,
          as: 'Days',
          include: [
            { model: ItineraryActivity, as: 'Activities' },
          ],
        },
      ],
    });

    if (!itinerary) {
      return res.status(404).json({ message: '일정을 찾을 수 없습니다.' });
    }

    res.status(200).json({ itinerary });
  } catch (error) {
    console.error('getItineraryById 오류:', error);
    next(error);
  }
};

exports.createItinerary = async (req, res, next) => {
  try {
    const { title, description, startDate, endDate, imageUrls, mapData, days } = req.body;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    if (!title || !description || !startDate || !endDate) {
      return res.status(400).json({ message: '제목, 설명, 시작일, 종료일이 필요합니다.' });
    }
    let e = checkMaxLength(title, LIMITS.itineraryTitle, '일정 제목');
    if (e) return res.status(400).json({ message: e });
    e = checkMaxLength(description, LIMITS.itineraryDescription, '일정 설명');
    if (e) return res.status(400).json({ message: e });

    const author = await User.findOne({ where: { firebase_uid: authorFirebaseUid } });
    if (!author) {
      return res.status(404).json({ message: '작성자를 찾을 수 없습니다.' });
    }

    const itinerary = await Itinerary.create({
      authorId: author.email,
      title,
      description,
      startDate,
      endDate,
      imageUrls: imageUrls || [],
      mapData: mapData || [],
    });

    if (days && days.length > 0) {
      for (const day of days) {
        const itineraryDay = await ItineraryDay.create({
          itineraryId: itinerary.id,
          dayNumber: day.dayNumber,
          date: day.date,
        });

        if (day.activities && day.activities.length > 0) {
          for (const activity of day.activities) {
            const at = activity.time != null ? String(activity.time).slice(0, LIMITS.activityTime) : null;
            const ad = activity.description != null ? String(activity.description).slice(0, LIMITS.activityDescription) : '';
            const al = activity.location != null ? String(activity.location).slice(0, LIMITS.activityLocation) : null;
            await ItineraryActivity.create({
              itineraryDayId: itineraryDay.id,
              time: at,
              description: ad,
              location: al,
              coordinates: activity.coordinates,
            });
          }
        }
      }
    }

    res.status(201).json({ message: '일정이 생성되었습니다.', itinerary });
  } catch (error) {
    console.error('createItinerary 오류:', error);
    next(error);
  }
};

exports.updateItinerary = async (req, res, next) => {
  try {
    const { itineraryId } = req.params;
    const { title, description, startDate, endDate, imageUrls, mapData, days } = req.body;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    const itinerary = await Itinerary.findByPk(itineraryId, {
      include: [{ model: User, as: 'Author' }],
    });

    if (!itinerary) {
      return res.status(404).json({ message: '일정을 찾을 수 없습니다.' });
    }

    // Authorization: Only the author can update their itinerary
    if (itinerary.Author.firebase_uid !== authorFirebaseUid) {
      return res.status(403).json({ message: '본인 일정만 수정할 수 있습니다.' });
    }
    let e;
    if (title != null) {
      e = checkMaxLength(title, LIMITS.itineraryTitle, '일정 제목');
      if (e) return res.status(400).json({ message: e });
    }
    if (description != null) {
      e = checkMaxLength(description, LIMITS.itineraryDescription, '일정 설명');
      if (e) return res.status(400).json({ message: e });
    }

    await itinerary.update({
      title: title || itinerary.title,
      description: description || itinerary.description,
      startDate: startDate || itinerary.startDate,
      endDate: endDate || itinerary.endDate,
      imageUrls: imageUrls || itinerary.imageUrls,
      mapData: mapData || itinerary.mapData,
    });

    // Handle nested updates for days and activities (more complex, consider a dedicated service or simpler approach)
    // For simplicity, this example just updates top-level itinerary.
    // Full nested update logic would involve deleting/recreating or finding/updating existing days/activities.
    if (days) {
      // Clear existing days and activities and recreate
      await ItineraryDay.destroy({ where: { itineraryId: itinerary.id } });

      for (const day of days) {
        const itineraryDay = await ItineraryDay.create({
          itineraryId: itinerary.id,
          dayNumber: day.dayNumber,
          date: day.date,
        });

        if (day.activities && day.activities.length > 0) {
          for (const activity of day.activities) {
            const at = activity.time != null ? String(activity.time).slice(0, LIMITS.activityTime) : null;
            const ad = activity.description != null ? String(activity.description).slice(0, LIMITS.activityDescription) : '';
            const al = activity.location != null ? String(activity.location).slice(0, LIMITS.activityLocation) : null;
            await ItineraryActivity.create({
              itineraryDayId: itineraryDay.id,
              time: at,
              description: ad,
              location: al,
              coordinates: activity.coordinates,
            });
          }
        }
      }
    }

    res.status(200).json({ message: '일정이 수정되었습니다.', itinerary });
  } catch (error) {
    console.error('updateItinerary 오류:', error);
    next(error);
  }
};

exports.deleteItinerary = async (req, res, next) => {
  try {
    const { itineraryId } = req.params;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    const itinerary = await Itinerary.findByPk(itineraryId, {
      include: [{ model: User, as: 'Author' }],
    });

    if (!itinerary) {
      return res.status(404).json({ message: '일정을 찾을 수 없습니다.' });
    }

    // Authorization: Only the author can delete their itinerary
    if (itinerary.Author.firebase_uid !== authorFirebaseUid) {
      return res.status(403).json({ message: '본인 일정만 삭제할 수 있습니다.' });
    }

    await itinerary.destroy(); // This will cascade delete ItineraryDays and ItineraryActivities

    res.status(204).send(); // No content for successful deletion
  } catch (error) {
    console.error('deleteItinerary 오류:', error);
    next(error);
  }
};
