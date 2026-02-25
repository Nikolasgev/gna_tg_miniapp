import React from 'react'
import { motion } from 'framer-motion'
import { Check, Star, Coffee } from 'lucide-react'

const Pricing = ({ onOpenModal }) => {
  const handlePlanClick = (plan, type) => {
    const serviceInfo = {
      type: type,
      name: plan.name,
      price: plan.price,
      period: plan.period,
      description: plan.description,
    }
    onOpenModal(serviceInfo)
  }

  const subscriptions = [
    {
      name: 'Старт',
      price: '2,900',
      period: 'в месяц',
      description: 'Для небольших кофеен',
      features: [
        'Каталог товаров с категориями',
        'Онлайн-заказы',
        'Онлайн-оплата (YooKassa)',
        'Самовывоз',
        'Админ-панель',
        'История заказов',
        'Telegram Mini App',
      ],
      popular: false,
      cta: 'Начать бесплатно',
    },
    {
      name: 'Бизнес',
      price: '5,900',
      period: 'в месяц',
      description: 'Для растущих кофеен',
      features: [
        'Всё из «Старт»',
        'Безлимитный каталог',
        'Интеграция с Яндекс Доставкой',
        'Автоматический расчет доставки',
        'Управление статусами заказов',
        'Firebase Authentication',
        'Настройки бизнеса (тема, логотип)',
      ],
      popular: true,
      cta: 'Выбрать тариф',
    },
    {
      name: 'Премиум',
      price: '11,900',
      period: 'в месяц',
      description: 'Для сетей кофеен',
      features: [
        'Всё из «Бизнес»',
        'Несколько бизнесов',
        'Приоритетная поддержка',
        'Кастомные настройки',
        'API доступ',
        'Расширенная статистика',
      ],
      popular: false,
      cta: 'Связаться с нами',
    },
  ]

  const oneTime = [
    {
      name: 'Старт',
      price: '29,000',
      period: 'разово',
      description: 'Внедрение для маленьких кофеен',
      features: [
        'Настройка каталога товаров',
        'Подключение YooKassa',
        'Настройка админ-панели',
        'Запуск Telegram Mini App',
        'Обучение работе с системой',
      ],
      popular: false,
      cta: 'Заказать внедрение',
    },
    {
      name: 'Бизнес',
      price: '59,000',
      period: 'разово',
      description: 'Внедрение для средних кофеен',
      features: [
        'Всё из «Старт»',
        'Интеграция с Яндекс Доставкой',
        'Настройка расчета доставки',
        'Загрузка каталога',
        'Настройка категорий',
        'Настройка бизнеса (тема, логотип)',
      ],
      popular: true,
      cta: 'Заказать внедрение',
    },
    {
      name: 'Премиум',
      price: '119,000',
      period: 'разово',
      description: 'Внедрение для сетей',
      features: [
        'Всё из «Бизнес»',
        'Настройка нескольких бизнесов',
        'API интеграции',
        'Кастомные настройки',
        'Персональный менеджер',
        'Обучение команды',
      ],
      popular: false,
      cta: 'Связаться с нами',
    },
  ]

  return (
    <section id="pricing" className="py-20 bg-gradient-to-br from-coffee-50 to-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Простые и{' '}
            <span className="text-gradient">прозрачные</span> цены
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Выберите тариф, который подходит вашей кофейне
          </p>
        </motion.div>

        {/* Подписки */}
        <div className="mb-20">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h3 className="text-3xl font-bold text-gray-900 mb-2">
              1. Подписки (ежемесячные)
            </h3>
            <p className="text-gray-600">
              Оплата каждый месяц. Можно отменить в любой момент.
            </p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            {subscriptions.map((plan, index) => {
              const handleClick = () => handlePlanClick(plan, 'subscription')
              return (
                <motion.div
                  key={plan.name}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                  className={`relative ${
                    plan.popular ? 'md:-mt-4 md:mb-4' : ''
                  }`}
                >
                  {plan.popular && (
                    <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                      <div className="bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 text-white px-4 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                        <Star className="w-4 h-4" />
                        Популярный
                      </div>
                    </div>
                  )}

                  <div
                    className={`bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all h-full flex flex-col ${
                      plan.popular
                        ? 'border-2 border-coffee-600'
                        : 'border border-coffee-100'
                    }`}
                  >
                    <div className="mb-6">
                      <h3 className="text-2xl font-bold text-gray-900 mb-2">
                        {plan.name}
                      </h3>
                      <p className="text-gray-600 text-sm mb-4">
                        {plan.description}
                      </p>
                      <div className="flex items-baseline">
                        <span className="text-5xl font-bold text-gray-900">
                          {plan.price} ₽
                        </span>
                        <span className="text-gray-500 ml-2">
                          / {plan.period}
                        </span>
                      </div>
                    </div>

                    <ul className="space-y-3 mb-8 flex-grow">
                      {plan.features.map((feature, idx) => (
                        <li key={idx} className="flex items-start">
                          <Check className="w-5 h-5 text-coffee-600 mr-3 flex-shrink-0 mt-0.5" />
                          <span className="text-gray-700 text-sm">{feature}</span>
                        </li>
                      ))}
                    </ul>

                    <button
                      onClick={handleClick}
                      className={`block w-full text-center py-3 px-6 rounded-full font-semibold transition-all mt-auto ${
                        plan.popular
                          ? 'bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 text-white hover:shadow-lg hover:scale-105'
                          : 'bg-coffee-50 text-coffee-700 hover:bg-coffee-100'
                      }`}
                    >
                      {plan.cta}
                    </button>
                  </div>
                </motion.div>
              )
            })}
          </div>
        </div>

        {/* Разовые услуги */}
        <div>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h3 className="text-3xl font-bold text-gray-900 mb-2">
              2. Разовые услуги
            </h3>
            <p className="text-gray-600 mb-2">
              Внедрение под ключ. Полная настройка и запуск вашей кофейни.
            </p>
            <p className="text-sm text-gray-500">
              Мы сделаем всё за вас: настроим каталог, подключим оплату и доставку, обучим команду.
            </p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            {oneTime.map((plan, index) => {
              const handleClick = () => handlePlanClick(plan, 'one-time')
              return (
                <motion.div
                  key={plan.name}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                  className={`relative ${
                    plan.popular ? 'md:-mt-4 md:mb-4' : ''
                  }`}
                >
                  {plan.popular && (
                    <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                      <div className="bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 text-white px-4 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                        <Star className="w-4 h-4" />
                        Популярный
                      </div>
                    </div>
                  )}

                  <div
                    className={`bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all h-full flex flex-col ${
                      plan.popular
                        ? 'border-2 border-coffee-600'
                        : 'border border-coffee-100'
                    }`}
                  >
                    <div className="mb-6">
                      <h3 className="text-2xl font-bold text-gray-900 mb-2">
                        {plan.name}
                      </h3>
                      <p className="text-gray-600 text-sm mb-4">
                        {plan.description}
                      </p>
                      <div className="flex items-baseline">
                        <span className="text-5xl font-bold text-gray-900">
                          {plan.price} ₽
                        </span>
                      </div>
                    </div>

                    <ul className="space-y-3 mb-8 flex-grow">
                      {plan.features.map((feature, idx) => (
                        <li key={idx} className="flex items-start">
                          <Check className="w-5 h-5 text-coffee-600 mr-3 flex-shrink-0 mt-0.5" />
                          <span className="text-gray-700 text-sm">{feature}</span>
                        </li>
                      ))}
                    </ul>

                    <button
                      onClick={handleClick}
                      className={`block w-full text-center py-3 px-6 rounded-full font-semibold transition-all mt-auto ${
                        plan.popular
                          ? 'bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 text-white hover:shadow-lg hover:scale-105'
                          : 'bg-coffee-50 text-coffee-700 hover:bg-coffee-100'
                      }`}
                    >
                      {plan.cta}
                    </button>
                  </div>
                </motion.div>
              )
            })}
          </div>
        </div>
      </div>
    </section>
  )
}

export default Pricing

